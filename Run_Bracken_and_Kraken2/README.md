# Guideline on how to run Bracken and Kraken2 using raw Nanopore fastq file on Ubuntu (for non-bioinformaticians).
## Date: 2026-01-06
## Computer IP: 10.64.148.20 (sequencing room computer)

### 1. Create a folder for analysis
Please do not mess up with the folder containing raw data.

### 2. Link the raw data folder to your targeted analysis folder
**Go to your analysis folder** and open it in terminal, and type the command below in terminal:

> [!NOTE]
> You have to copy the absolute path of the raw Nanopore folder named "no_sample_id"!

```bash
ln -s /var/lib/minknow/data/Nanopore20260106/no_sample_id
```
<img width="704" height="55" alt="image" src="https://github.com/user-attachments/assets/67357af0-4937-45a1-994b-cadddb8919fe" />

> [!TIP]
> You can open the raw folder in terminal and get the absolute path using command `pwd`

### 3. Enter `/media/kt_jdip/Data_Drive/Bracken_script` and copy all the srcipts into your analysis folder
If you want to use command line: `cp /media/kt_jdip/Data_Drive/Bracken_script/* .`
### 4. Modify file `work.sh` in your analysis folder
<img width="747" height="116" alt="image" src="https://github.com/user-attachments/assets/3f5e203e-62bb-42e3-8a76-da9b910c1754" />

> [!NOTE]
> **Only the followings need to change:**
> - --start_bc: starting barcode number, e.g. `01`
> - --end_bc: ending barcode number, e.g. `24`
> - --raw_dir: subfolder name under `no_sample_id`
>   - <img width="737" height="100" alt="image" src="https://github.com/user-attachments/assets/d6fc81c1-9084-444e-92c1-160066bc94f4" >
> - --data_hps: sequencing hour, e.g. `12`
### 5. Run the analysis
Command line: `nohup bash work.sh` and later you will see the output named `xxhps`, e.g. `12hps` (if you specified `--data_hps 12`):

<img width="640" height="255" alt="image" src="https://github.com/user-attachments/assets/830854b8-6994-4a2a-9ef2-b86aecbc0f5d" />

```
12hps/
├── barcode01.fastq.gz
├── ...
├── bracken   <------------------------------------------------------ Bracken reports
│   └── 0.1
│       ├── nohuman_barcode01.ppf.0.1.bracken
│       ├── nohuman_barcode01.ppf.0.1_bracken_species.kraken2_report
│       └── ...
├── kraken2   <------------------------------------------------------ Kraken2 reports
│   └── 0.1
│       ├── nohuman_barcode01.ppf.0.1.kraken2_output.gz
│       ├── nohuman_barcode01.ppf.0.1.kraken2_report
│       └── ...
└── nohuman_barcode01.fastq.gz
```
