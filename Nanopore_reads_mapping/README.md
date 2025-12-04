# Nanopore Read Mapping Script  
A general-purpose Bash script for mapping Oxford Nanopore reads to a reference genome using minimap2 & samtools.
The script is on computer IP: 10.64.148.20 (Sequencing room right computer)

---
## Content
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [Example](#example)
  - [MERS-CoV (Nanopore20251203_2)](#mers-cov-nanopore20251203_2)

---

## Usage
```bash
MAP_Nanopore_READS="/home/kt_jdip/aixin/14.MERS-CoV_mapping/map_nanopore_reads.sh"

bash $MAP_Nanopore_READS -r reference.fasta -i reads.fastq[.gz] -o output_prefix [options]
```


## Parameters

| Flag | Description |
|------|-------------|
| `-r` | Reference genome (FASTA) |
| `-i` | Nanopore reads (FASTQ or FASTQ.gz) |
| `-o` | Output prefix |
| `-t` | Number of threads (default: 8) |
| `-x` | Minimap2 preset (default: `map-ont`) |
| `-a` | Additional minimap2 arguments |
| `-h` | Show help message |

---

## Output

After successful execution, the script outputs:

- `<prefix>.bam` — sorted BAM alignment file  
- `<prefix>.bam.bai` — BAM index  
- `<reference>.mmi` — minimap2 index (auto-created if absent)

---

## Examples

### MERS-CoV (Nanopore20251203_2)
- Script: `bash map_nanopore_reads.sh -r JX869059.fasta -i barcode01_24hps.fastq.gz -o barcode01_24hps`
- Results: /media/kt_jdip/Data_Drive/Nanopore20251203_2
   
