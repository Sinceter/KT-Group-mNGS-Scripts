#!/bin/bash

# Configuration file for metagenomics analysis pipeline
# Update these paths according to your system setup

# Program paths (sequencing room right computer)
#BRACKEN_EXC="/home/kt_jdip/Bracken-2.7/bracken"
#MINIMAP2_EXC="/home/kt_jdip/miniconda3/bin/minimap2"
#SAMTOOLS_EXC="/usr/bin/samtools"
#PIGZ_EXC="/usr/bin/pigz"
#SEQKIT_EXC="/home/kt_jdip/miniconda3/bin/seqkit"
#KRAKEN2_SERVER_EXC="/home/kt_jdip/miniconda3/envs/kraken2/bin/kraken2_server"
#KRAKEN2_CLIENT_EXC="/home/kt_jdip/miniconda3/envs/kraken2/bin/kraken2_client"
#CONDA_EXC="/home/kt_jdip/miniconda3/etc/profile.d/conda.sh"

# Database paths (sequencing room right computer)
#HUMAN_MMI="/home/kt_jdip/Desktop/human.mmi"
#K2_PLUSPF_DB="/home/kt_jdip/Desktop/k2_pluspf_20250402"
#K2_EUPATH_DB="/home/kt_jdip/Desktop/k2_eupathdb48_20201113"
#K2_SILVA_DB="/home/kt_jdip/Desktop/16S_SILVA132_k2db"

# Program paths (cvvt server)
BRACKEN_EXC="/home/kelvinto/miniconda3/envs/kb/bin/bracken"
MINIMAP2_EXC="/home/kelvinto/miniconda3/bin/minimap2"
SAMTOOLS_EXC="/usr/bin/samtools"
PIGZ_EXC="/usr/bin/pigz"
SEQKIT_EXC="/home/kelvinto/miniconda3/bin/seqkit"
KRAKEN2_SERVER_EXC="/home/kelvinto/miniconda3/envs/kb/bin/kraken2_server"
KRAKEN2_CLIENT_EXC="/home/kelvinto/miniconda3/envs/kb/bin/kraken2_client"

# Database paths (cvvt server)
HUMAN_MMI="/home/kelvinto/kelvinto/Daniel/RNA_Analysis/genome/human.mmi"
K2_PLUSPF_DB="/home/kelvinto/kelvinto/Kraken2/k2_pluspf_20250402"
K2_EUPATH_DB="/home/kelvinto/kelvinto/Kraken2/k2_eupathdb48_20230407"
K2_SILVA_DB="/home/kelvinto/kelvinto/Kraken2/16S_Silva132_20200326"

# Default parameters
NTHREADS=24
DATA_HPS_DEFAULT=24
