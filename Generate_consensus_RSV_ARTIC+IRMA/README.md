# RSV Consensus Generation Pipeline (ARTIC + IRMA)
This is based on the paper 

## Content
- [Description](#description)
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [Example](#example)

## Description
Based on **Nanopore (ONT)** sequencing reads, this pipeline:
1. Optionally filters reads by length.  
2. Uses **ARTIC minion** to trim primers and generate an initial consensus.  
3. Extracts post–primer-trim reads with **samtools ampliconclip** (hard-clip) and converts them back to FASTQ.  
4. Runs **IRMA (RSV module)** to generate final consensus sequences.

> [!NOTE]
> This script follows the depth threshold mentioned in *doi:10.1111/irv.70106* (default `--min_depth 40` for ARTIC).  
> Current implementation targets **ONT single-end** data; `--platform` exists for future extension.

---

## Usage
Run the pipeline for a single sample:

```bash
cd <your working directory>
SCRIPT="/path/to/your/script.sh"

# Minimal
bash "$SCRIPT" \
  --fastq <reads.fastq.gz> \
  --primerref <primer_numbering_reference.fasta> \
  --primerbed <primer_artic.bed>

# With typical options
bash "$SCRIPT" \
  --fastq <reads.fastq.gz> \
  --primerref <primer_numbering_reference.fasta> \
  --primerbed <primer_artic.bed> \
  --minlen 1500 --maxlen 3000 \
  --min_depth 40 \
  --threads 24 \
  --outdir results
```

>[!NOTE]
> The script activates a Conda environment named artic. Make sure:
> source /home/kelvinto/miniconda3/etc/profile.d/conda.sh works on your system
> The artic env contains artic, samtools (with ampliconclip), bbtools (reformat.sh), pigz, and IRMA.


