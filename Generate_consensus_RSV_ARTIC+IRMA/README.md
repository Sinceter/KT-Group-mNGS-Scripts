# RSV Consensus Generation Pipeline (ARTIC + Medaka) V2 
This pipeline is modified according to the method described in the paper [doi:10.1111/irv.70106](https://github.com/Sinceter/KT-Group-mNGS-Scripts/blob/main/Generate_consensus_RSV_ARTIC%2BIRMA/Influenza%20Resp%20Viruses%20-%202025%20-%20Dong%20-%20An%20Improved%20Rapid%20and%20Sensitive%20Long%20Amplicon%20Method%20for%20Nanopore%E2%80%90Based%20RSV.pdf). 
## Update: 2025-11-24
## Change: Use Medaka+Nextclade [RSV_A_PP109421](https://www.ncbi.nlm.nih.gov/nuccore/PP109421.1) / [RSV_B_OP975389](https://www.ncbi.nlm.nih.gov/nuccore/<RSV refenrece>) reference (downloaded on 2025-11-20) to generate concensus, instead of using IRMA pipeline+IRMA reference.

<img width="1920" height="967" alt="image" src="https://github.com/user-attachments/assets/53174697-71a6-48a0-a824-fd277e4b7608" />
<img width="1920" height="967" alt="image" src="https://github.com/user-attachments/assets/0a5ce45f-99be-4bb3-b1ef-0bf21266982a" />


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
3. Extracts post–primer-trim reads and runs **Medaka (RSV module)** to generate final consensus sequences.
> [!WARNING]
> You can run this pipeline only if you can access to CVVT server (KT group).

---

## Usage
Run the pipeline for a single sample:

```bash
# The simplest try is running:
cd <your working directory>
SCRIPT="/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/RSV_consensus.pipeline_V2.sh"
bash $SCRIPT --fastq <reads.fastq.gz>
```

```bash
# or you can try with other options
cd <your working directory>
SCRIPT="/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/RSV_consensus.pipeline_V2.sh"
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
RSV_pipeline_20251124-1448/                                      ---> # This is the output directory, following are important outputs you need to pay attention to:
├── Filter_len<MIN>-<MAX>bp_<sample>.fastq.gz                    ---> # (If length filtering was requested)
├── ...
├── <sample>.intermediate.artic.consensus.fasta                  ---> # ARTIC-generated intermediate consensus
├── <sample>.primertrimmed.rg.sorted.bam                         ---> # ARTIC output of reads mapping bam file
├── <sample>_trimmed.forIRMA.fastq.gz                            ---> # ARTIC output of hard-clipped reads
├── ...
├── <sample>_<RSV refenrece>_ARTIC+medaka_calls_to_draft.bam     ---> # Final consensus bam file 
├── <sample>_<RSV refenrece>_ARTIC+medaka_calls_to_draft.bam.bai ---> # Final consensus bam index file 
├── <sample>_<RSV refenrece>_ARTIC+medaka_consensus.fasta        ---> # Final consensus
├── ...
├── medaka_rsva/
├── medaka_rsvb/
└── tmp/
```
> [!NOTE]
> The final consensus sequence is `<sample>_<RSV reference>_ARTIC+IRMA_consensus.fasta`; If this file does not exist, then the consensus sequence can not be generated from the sample you provided.


---


## Example

### RSV (Nanopore20251015)
- Consensus generated using IRMA default RSV references: `/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/Nanopore20251015_consensus_IRMARef/summary`
- (NEW) Consensus generated using Nextclade RSV references: `/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/Nanopore20251015_consensus_ARTIC+Medaka_NextcladeRef/summary`

### RSV (Nanopore20251118)
- Consensus generated using Nextclade RSV references: `/home/kelvinto/kelvinto/aixin/07.temp-tasks/07.20250919_RSV-surveillance-consensus-pipe/Nanopore20251118_consensus_ARTIC+Medaka_NextcladeRef/summary`
