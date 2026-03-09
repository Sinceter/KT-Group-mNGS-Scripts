#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import pandas as pd
from bs4 import BeautifulSoup


SECTION_ALIASES = {
    "patient": ["patient"],
    "quality_control": ["quality control"],
    "tax_above_threshold": [
        "taxonomic classification - organisms above threshold",
        "taxonomic classification- organisms above threshold",
        "organisms above threshold",
    ],
    "viral_report": ["viral report"],
}

MISSING_VALUES = {"", "nan", "none", "null", "-", "na", "n/a"}


def normalize_text(text: str) -> str:
    text = str(text).replace("\xa0", " ")
    text = re.sub(r"\s+", " ", text).strip()
    return text


def canonicalize_header(text: str) -> str:
    text = normalize_text(text).lower()
    text = text.replace("(", " ").replace(")", " ")
    text = text.replace("/", " ")
    text = re.sub(r"[^a-z0-9%+]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text


def looks_like_section_title(text: str) -> bool:
    t = normalize_text(text)
    return 0 < len(t) < 120


def find_section_header(tag) -> Optional[str]:
    for prev in tag.find_all_previous(limit=30):
        name = getattr(prev, "name", None)
        if name in {"h1", "h2", "h3", "h4", "h5", "h6", "b", "strong", "caption"}:
            txt = normalize_text(prev.get_text(" ", strip=True))
            if looks_like_section_title(txt):
                return txt
        if name == "p":
            txt = normalize_text(prev.get_text(" ", strip=True))
            if looks_like_section_title(txt) and len(txt) <= 80:
                return txt
    return None


def match_section(title: str) -> Optional[str]:
    t = normalize_text(title).lower()
    for key, aliases in SECTION_ALIASES.items():
        for alias in aliases:
            if alias in t:
                return key
    return None


def html_tables_with_titles(html_text: str) -> List[Tuple[Optional[str], pd.DataFrame]]:
    soup = BeautifulSoup(html_text, "lxml")
    tables = []
    for table in soup.find_all("table"):
        try:
            dfs = pd.read_html(str(table))
        except ValueError:
            continue
        if not dfs:
            continue
        title = find_section_header(table)
        for df in dfs:
            tables.append((title, df))
    return tables


def clean_df(df: pd.DataFrame) -> pd.DataFrame:
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = [
            normalize_text(" ".join([str(x) for x in col if str(x) != "nan"]))
            for col in df.columns
        ]
    else:
        df.columns = [normalize_text(str(c)) for c in df.columns]

    df = df.dropna(axis=0, how="all").dropna(axis=1, how="all").copy()

    for col in df.columns:
        df[col] = df[col].map(lambda x: normalize_text(x) if pd.notna(x) else "")

    return df


def table_to_key_value(df: pd.DataFrame) -> Dict[str, str]:
    df = clean_df(df)

    if df.shape[1] == 2:
        out = {}
        for _, row in df.iterrows():
            k = canonicalize_header(row.iloc[0])
            v = normalize_text(row.iloc[1])
            if k:
                out[k] = v
        return out

    if df.shape[1] > 2 and df.shape[1] % 2 == 0:
        out = {}
        for _, row in df.iterrows():
            vals = list(row.values)
            for i in range(0, len(vals), 2):
                k = canonicalize_header(vals[i])
                v = normalize_text(vals[i + 1])
                if k and k not in {"", "nan"}:
                    out[k] = v
        if out:
            return out

    if df.shape[0] == 1:
        out = {}
        row = df.iloc[0]
        for col in df.columns:
            k = canonicalize_header(col)
            v = normalize_text(row[col])
            if k:
                out[k] = v
        return out

    return {}


def find_column(df: pd.DataFrame, candidates: List[str]) -> Optional[str]:
    cols_norm = {canonicalize_header(c): c for c in df.columns}
    for cand in candidates:
        c = canonicalize_header(cand)
        if c in cols_norm:
            return cols_norm[c]
    for norm, raw in cols_norm.items():
        for cand in candidates:
            cand_norm = canonicalize_header(cand)
            if cand_norm in norm:
                return raw
    return None


def parse_taxonomy_table(df: pd.DataFrame) -> List[str]:
    df = clean_df(df)
    organism_col = find_column(df, ["Organism", "Species"])
    counts_col = find_column(df, ["Counts", "Count", "Reads"])
    pct_col = find_column(df, ["Percentage", "%", "Percent", "Abundance", "Organism percentage abundance"])

    if not organism_col:
        return []

    items = []
    for _, row in df.iterrows():
        organism = normalize_text(row.get(organism_col, ""))
        if canonicalize_header(organism) in MISSING_VALUES or not organism:
            continue

        counts = normalize_text(row.get(counts_col, "")) if counts_col else ""
        pct = normalize_text(row.get(pct_col, "")) if pct_col else ""

        if pct and not pct.endswith("%"):
            pct = f"{pct}%"

        if counts and pct:
            items.append(f"{organism} ({counts}; {pct})")
        elif counts:
            items.append(f"{organism} ({counts})")
        else:
            items.append(organism)

    return items


def parse_viral_table(df: pd.DataFrame) -> List[str]:
    df = clean_df(df)
    organism_col = find_column(df, ["Organism", "Species"])
    counts_col = find_column(df, ["Counts", "Count", "Reads"])

    if not organism_col:
        return []

    items = []
    for _, row in df.iterrows():
        organism = normalize_text(row.get(organism_col, ""))
        if canonicalize_header(organism) in MISSING_VALUES or not organism:
            continue

        counts = normalize_text(row.get(counts_col, "")) if counts_col else ""
        if counts:
            items.append(f"{organism} ({counts})")
        else:
            items.append(organism)

    return items


def parse_report(html_path: Path) -> Dict[str, str]:
    text = html_path.read_text(encoding="utf-8", errors="ignore")
    tables = html_tables_with_titles(text)

    patient_data: Dict[str, str] = {}
    qc_data: Dict[str, str] = {}
    tax_items: List[str] = []
    viral_items: List[str] = []

    for title, df in tables:
        section = match_section(title or "")
        if section == "patient":
            parsed = table_to_key_value(df)
            if parsed and len(parsed) >= len(patient_data):
                patient_data = parsed
        elif section == "quality_control":
            parsed = table_to_key_value(df)
            if parsed and len(parsed) >= len(qc_data):
                qc_data = parsed
        elif section == "tax_above_threshold":
            items = parse_taxonomy_table(df)
            if items:
                tax_items = items
        elif section == "viral_report":
            items = parse_viral_table(df)
            if items:
                viral_items = items

    row: Dict[str, str] = {"source_file": html_path.name}

    wanted_patient_keys = [
        "lab_sample_id",
        "date_time",
        "workflow_version",
        "barcode",
        "sample_type",
        "sample_class",
        "time_interval",
        "database_version",
    ]
    wanted_qc_keys = [
        "total_microbial_reads",
        "total_reads",
        "total_human_reads_count_percent_of_total_reads",
        "total_bases",
        "mean_read_length",
        "mean_read_quality",
        "unclassified",
        "below_threshold",
    ]

    for k in wanted_patient_keys:
        row[k] = patient_data.get(k, "")
    for k in wanted_qc_keys:
        row[k] = qc_data.get(k, "")

    row["organisms_combined"] = "; ".join(tax_items + viral_items)
    row["organisms_above_threshold"] = "; ".join(tax_items)
    row["viral_report"] = "; ".join(viral_items)

    return row


def collect_html_files(input_path: Path) -> List[Path]:
    if input_path.is_file() and input_path.suffix.lower() in {".html", ".htm"}:
        return [input_path]
    if input_path.is_dir():
        return sorted(
            [p for p in input_path.rglob("*") if p.suffix.lower() in {".html", ".htm"}]
        )
    return []


def build_dataframe(files: List[Path]) -> tuple[pd.DataFrame, List[tuple[str, str]]]:
    rows = []
    failures = []

    for f in files:
        try:
            rows.append(parse_report(f))
        except Exception as e:
            failures.append((f.name, str(e)))

    df = pd.DataFrame(rows)

    preferred_order = [
        "source_file",
        "lab_sample_id",
        "date_time",
        "time_interval",
        "sample_type",
        "sample_class",
        "barcode",
        "workflow_version",
        "database_version",
        "total_microbial_reads",
        "total_reads",
        "total_human_reads_count_percent_of_total_reads",
        "total_bases",
        "mean_read_length",
        "mean_read_quality",
        "unclassified",
        "below_threshold",
        "organisms_combined",
        "organisms_above_threshold",
        "viral_report",
    ]
    if not df.empty:
        cols = [c for c in preferred_order if c in df.columns] + [c for c in df.columns if c not in preferred_order]
        df = df[cols]

    return df, failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Batch parse Agnes HTML reports.")
    parser.add_argument("input", help="HTML file or directory containing HTML reports")
    parser.add_argument(
        "-o",
        "--output",
        default="agnes_report_summary.csv",
        help="Output CSV path (default: agnes_report_summary.csv)",
    )
    parser.add_argument(
        "--xlsx",
        default="",
        help="Optional XLSX output path",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    files = collect_html_files(input_path)

    if not files:
        print(f"No HTML files found in: {input_path}", file=sys.stderr)
        return 1

    df, failures = build_dataframe(files)

    output_csv = Path(args.output)
    df.to_csv(output_csv, index=False, encoding="utf-8-sig")

    if args.xlsx:
        output_xlsx = Path(args.xlsx)
        df.to_excel(output_xlsx, index=False)

    if failures:
        fail_path = output_csv.with_name(output_csv.stem + "_failures.csv")
        pd.DataFrame(failures, columns=["source_file", "error"]).to_csv(
            fail_path, index=False, encoding="utf-8-sig"
        )
        print(f"Parsed {len(df)} files, failed {len(failures)} files.")
        print(f"Failure log: {fail_path}")
    else:
        print(f"Parsed {len(df)} files successfully.")

    print(f"CSV written to: {output_csv}")
    if args.xlsx:
        print(f"XLSX written to: {args.xlsx}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
