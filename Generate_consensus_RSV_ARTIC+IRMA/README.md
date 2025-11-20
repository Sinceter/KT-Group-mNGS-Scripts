# RSV Consensus Generation Pipeline (ARTIC + IRMA)
This pipeline is build according to the method described in the paper [doi:10.1111/irv.70106](https://github.com/Sinceter/KT-Group-mNGS-Scripts/blob/main/Generate_consensus_RSV_ARTIC%2BIRMA/Influenza%20Resp%20Viruses%20-%202025%20-%20Dong%20-%20An%20Improved%20Rapid%20and%20Sensitive%20Long%20Amplicon%20Method%20for%20Nanopore%E2%80%90Based%20RSV.pdf). 


## Content
- [Description](#description)
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [Example](#example)
  -  [RSV (Nanopore20251015)](#rsv-nanopore20251015)
  -  [RSV (Nanopore20251118)](#rsv-nanopore20251118)

## Description
Based on **Nanopore (ONT)** sequencing reads, this pipeline:
1. Can optionally filter reads by length (only when both --minlen and --maxlen are provided);
2. Uses **ARTIC minion** to trim primer sets ([see the supplementary table 1](https://github.com/Sinceter/KT-Group-mNGS-Scripts/blob/main/Generate_consensus_RSV_ARTIC%2BIRMA/An%20Improved%20Rapid%20and%20Sensitive%20Long%20Amplicon%20Method%20for%20Nanopore%E2%80%90Based%20RSV_suppl-file_1.pdf)) first;  
3. Extracts post–primer-trim reads and runs **IRMA (RSV module)** to generate final consensus sequences.
> [!WARNING]
> You can run this pipeline only if you can access to CVVT server (KT group).

---

## Usage
Run the pipeline for a single sample:

```bash
# The simplest try is running:
cd <your working directory>
SCRIPT="/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/RSV_consensus.pipeline.sh"
bash $SCRIPT --fastq <reads.fastq.gz>
```

```bash
# or you can try with other options
cd <your working directory>
SCRIPT="/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/RSV_consensus.pipeline.sh"
bash $SCRIPT \
  --fastq <reads.fastq.gz> \
  --minlen <optional> --maxlen <optional> \
  --min_depth <optional, default: 40> \
  --threads <optional, default: 24> \
  --outdir <optional, default: RSV_pipeline_date>
```

---

## Parameters
The pipeline accepts the following parameters (long options only):

| Parameter | Required | Default | Description |
|------------|-----------|----------|--------------|
| `--fastq` | yes | — | Input FASTQ (supports `.fastq` or `.fastq.gz`). A single file is expected for ONT. |
| `--minlen` | no | — | Minimum read length (used only if `--maxlen` is also provided). |
| `--maxlen` | no | — | Maximum read length (used only if `--minlen` is also provided). |
| `--platform` | no | `ont` | `ont` or `illumina` (currently only ONT supported). |
| `--min_depth` | no | `40` | Minimum reads depth for ARTIC consensus. |
| `--threads` | no | `24` | Number of threads. |
| `--outdir` | no | `RSV_pipeline_YYYYMMDD-HHMM` | Output directory. |


---

## Output
A new timestamped directory is created (or the one you provide via --outdir) and populated with:

```
<OUTDIR>/
├── Filter_len<MIN>-<MAX>bp_<sample>.fastq.gz   ---> # (if length filtering was requested)
├── <sample>.intermediate.artic.consensus.fasta ---> # ARTIC-generated intermediate consensus
├── <sample>.primertrimmed.rg.sorted.bam        ---> # ARTIC output 
├── <sample>.primertrimmed.rg.sorted.bam.bai
├── <sample>_trimmed.forIRMA.fastq.gz           ---> # hard-clipped reads fro ARTIC output for IRMA module
├── <sample>_IRMA/                              ---> # IRMA module intermediate files
│   ├── RSV_AD.fasta                            
│   └── RSV_BD.fasta
├── <sample>_RSV_AD_ARTIC+IRMA_consensus.fasta  ---> # final consensus (if AD produced, then it is RSV A virus)
└── <sample>_RSV_BD_ARTIC+IRMA_consensus.fasta  ---> # final consensus (if BD produced, then it is RSV B virus)
```
> [!NOTE]
> The final consensus sequence is `<sample>_RSV_AD/BD_ARTIC+IRMA_consensus.fasta`; If this file does not exist, then the consensus sequence can not be generated from the sample you provided.


---


## Example

### RSV (Nanopore20251015)
- Consensus generated using IRMA default RSV references: `/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/Nanopore20251015_consensus_IRMA_consensus/summary`
- (NEW) Consensus generated using Nextclade RSV references: `/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/Nanopore20251015_consensus_Nextclade_consensus/summary`

### RSV (Nanopore20251118)
- Consensus generated using Nextclade RSV references: `/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/Nanopore20251118_consensus_Nextclade_consensus/summary`
