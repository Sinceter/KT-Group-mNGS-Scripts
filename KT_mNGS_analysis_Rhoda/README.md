# Metagenomic NGS Analysis

![Version](https://img.shields.io/badge/version-1.0-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Status](https://img.shields.io/badge/status-active-brightgreen)

**Author: Rhoda Leung** | *Bash script for processing Nanopore raw data to generate Kraken2 and Bracken reports for metagenomic analysis.*

This script (`mNGS_analysis.sh`) streamlines metagenomic analysis by processing barcode-based Nanopore data, removing human reads, performing taxonomic classification, and generating detailed reports. It supports optional sequence filtering and report renaming using a CSV file, with organized outputs for easy access.

---

## 📋 Table of Contents

- [Features](#-features)
- [Setup](#-setup)
  - [Requirements](#requirements)
  - [Dependency Versions](#dependency-versions)
  - [Installation](#installation)
- [Usage](#-usage)
  - [Required Parameters](#required-parameters)
  - [Optional Parameters](#optional-parameters)
  - [Example](#example)
- [CSV File Format](#-csv-file-format)
- [Output](#-output)
- [Notes](#-notes)
- [Contact](#-contact)

---

## 🌟 Features

- 🧬 **Human Read Removal**: Filters out human reads from Nanopore FASTQ files using Minimap2 and Samtools.
- 🔍 **Taxonomic Classification**: Performs classification with Kraken2 using customizable databases (PlusPF, EuPathDB, Silva).
- 📊 **Species Abundance**: Generates Bracken reports for species-level abundance estimation.
- ✂️ **Sequence Filtering**: Optionally filters sequences by minimum length.
- 🏷️ **Report Renaming**: Renames Kraken2 and Bracken reports with sample names from a CSV file.
- 🗂️ **Organized Outputs**: Moves intermediate files to a dedicated directory and logs all actions.

---

## 🛠️ Setup

### Requirements

- **Software**:
  - Bash, Minimap2, Samtools, SeqKit, Pigz, Kraken2, Kraken2-server, Bracken, Conda
  - Standard Unix utilities: `awk`, `sed`, `grep`, `find`
- **Configuration**:
  - A `config.sh` file with paths to executables and databases (e.g., `K2_PLUSPF_DB`, `HUMAN_MMI`)
- **Input Files**:
  - Nanopore raw data directories with `fastq_pass/barcodeXX` subdirectories
  - Optional `samples.csv` for sample name mapping
- **Dependencies**:
  - `run_kraken2-server.sh` (Kraken2 server script, copied to output directory)

### Dependency Versions

<details>
<summary>View Dependency Versions</summary>

The script was developed and tested with the following versions. Ensure your system matches these or newer compatible versions:

| Tool           | Version   |
|----------------|-----------|
| Bash           | 5.1.16    |
| Minimap2       | 2.28-r1209|
| Samtools       | 1.21      |
| SeqKit         | 2.8.2     |
| Pigz           | 2.8       |
| Kraken2        | 2.1.3     |
| Kraken2-server | 2.1.3     |
| Bracken        | 2.7       |


**Note**: Versions were tested on a Linux system (Ubuntu 22.04). On macOS or other systems, BSD utilities may replace GNU versions, but functionality should remain compatible. Verify your versions for compatibility.

</details>

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-repo/mNGS_analysis.git
   cd mNGS_analysis
   ```

2. **Configure `config.sh`**:
   - Update paths to executables and databases (e.g., `K2_PLUSPF_DB`, `HUMAN_MMI`).

3. **Provide `run_kraken2-server.sh`**:
   - Ensure `run_kraken2-server.sh` is in the same directory as `mNGS_analysis.sh`.

4. **Install Dependencies via Conda**:
   ```bash
   conda create -n kraken2 -c conda-forge -c bioconda -c nanoporetech minimap2 samtools seqkit pigz kraken2 kraken2-server bracken
   conda activate kraken2
   ```

5. **Verify Versions**:
   - Check dependency versions with commands like:
     ```bash
     minimap2 --version
     seqkit version
     ```

---

## 🚀 Usage

Run the script with required and optional parameters:

```bash
bash mNGS_analysis.sh --start_bc 05 --end_bc 07 --raw_dir "path/to/run1,path/to/run2" [--data_hps <hours>] [--kraken2_db <database>] [--csv <file>] [--filter_seq <length>]
```

### Required Parameters

| Parameter      | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| `--start_bc`   | Starting barcode number (two digits with leading zero, e.g., `05` for `barcode05`). |
| `--end_bc`     | Ending barcode number (two digits with leading zero, e.g., `07` for `barcode07`).   |
| `--raw_dir`    | Comma-separated list of Nanopore run directories (e.g., `20250401_1617_MN33269_FBB43311_bef60500`). |

### Optional Parameters

| Parameter      | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| `--data_hps`   | Hours post sequencing for output directory naming (default: defined in `config.sh`). |
| `--kraken2_db` | Kraken2 database choice: `ppf_only`, `ppf+eupath` (default), `ppf+eupath+silva`. |
| `--csv`        | Path to a CSV file mapping barcodes to sample names (e.g., `samples.csv`).     |
| `--filter_seq` | Minimum read length for filtering (e.g., `1000`; if not set, filtering is skipped). |

### Example

Process barcodes `barcode05` to `barcode07` with a CSV file and sequence filtering:

```bash
bash mNGS_analysis.sh --start_bc 05 --end_bc 07 --raw_dir "20250401_1617_MN33269_FBB43311_bef60500,20230416_1520_MN34403_FAY26260_255430c4" --csv samples.csv --filter_seq 1000
```

---

## 📄 CSV File Format

If using the `--csv` option, provide a `samples.csv` file with two columns: `barcode` and `sample_name`. The `barcode` column **must** contain two-digit barcode numbers with leading zeros (e.g., `05` for `barcode05`), matching the `--start_bc` and `--end_bc` format.

**Example `samples.csv`**:
```csv
barcode,sample_name
05,SampleA
06,SampleB
07,SampleC
```

The script uses these sample names to prefix Kraken2 and Bracken reports (e.g., `SampleA_nohuman_barcode05.ppf.0.0.kraken2_report`).

---

## 📂 Output

The script creates an output directory named `<data_hps>hps` (e.g., `48hps`) containing:

- **Kraken2 Reports**: `kraken2/<cs>/*.kraken2_report` (and `filtered_<length>` for filtered reads).
- **Bracken Reports**: `bracken/<cs>/*.bracken_report` (renamed from `*_bracken_species.kraken2_report`).
- **Intermediate Files**: Moved to `intermediate_files/` (e.g., `*.ppf.*.*.bracken`).
- **Log File**: `metagenomics_analysis_<timestamp>.log` with detailed execution logs.
- **FASTQ Files**: `nohuman_barcodeXX.fastq.gz` (after human read removal) and filtered versions if `--filter_seq` is used.

*Note*: Kraken2 output files (e.g., `*.kraken2_output.gz`) are not renamed and remain in `kraken2/<cs>/`.

---

## ℹ️ Notes

<details>
<summary>View Notes</summary>

- **Barcode Format**: Barcodes in `--start_bc`, `--end_bc`, and the CSV file must be two-digit numbers with leading zeros (e.g., `05`, not `5`).
- **Kraken2 Server**: Ensure `run_kraken2-server.sh` is present, as it is copied to the output directory and used for Kraken2 analysis.
- **Validation**: The script checks that `--start_bc` and `--end_bc` are two-digit numbers between `01` and `99`, and that `--start_bc` is not greater than `--end_bc`.
- **No sample CSV**: If no CSV file is provided, reports retain their original names (e.g., `nohuman_barcode05.ppf.0.0.kraken2_report`).
- **MinKNOW Version**: The script expects Nanopore data generated by MinKNOW version 24.11.8 to ensure compatibility with the no_sample_id/*/fastq_pass/barcodeXX directory raw data structure.
- **Bracken Reports**: `bracken/<cs>/*_bracken_species.kraken2_report` (prefixed with sample names from CSV if provided).
- **Dependency Versions**: Verify your system’s dependency versions match those listed (see [Dependency Versions](#dependency-versions)).

</details>

---

## 📬 Contact

For issues or questions, contact **Rhoda Leung** or open an issue on the [GitHub repository](https://github.com/your-repo/mNGS_analysis).
