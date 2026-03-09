# Agnes HTML Parser

Parse Agnes / CIDR HTML reports in batch, extracting information from following 4 parts：

- Patient
- Quality Control
- Taxonomic classification - Organisms above Threshold
- Viral report

Output: concise summary table - one sample per row。

## Characteristics

- Support batch parsing of individual HTML files or entire directories
- `organisms_combined`：
  1. `Taxonomic classification - Organisms above Threshold`
  2. `Viral report`
- taxonomy format (reads number; microbial percentage)：
  - `species 1 (466; 36.41%)`
- viral format (reads number only)：
  - `virus 1 (314)`

## Installation

```bash
python3 -m pip install -r requirements.txt
```

## Usage
- Input: html file
```
python3 agnes_html_parser.py sample_report.html
```
- Input: folder path
```
python3 agnes_html_parser.py /path/to/html_dir
```
- Output: csv file
```
python3 agnes_html_parser.py /path/to/html_dir -o summary.csv
```
- Output: Excel file
```
python3 agnes_html_parser.py /path/to/html_dir -o summary.csv --xlsx summary.xlsx
```
