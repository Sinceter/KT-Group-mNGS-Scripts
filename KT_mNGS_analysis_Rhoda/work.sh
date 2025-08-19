#!/bin/bash

bash ./mNGS_analysis.sh --start_bc 01 \
	--end_bc 24 \
	--raw_dir <folder/name/under/no_sample_id> \
	--data_hps  12 \
	--kraken2_db ppf_only \
	--csv sample_template.csv
