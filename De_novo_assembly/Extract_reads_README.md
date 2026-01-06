# Guideline on how to extract reads for certain species and do assembly (optional)
## Date: 2026-01-06
## Computer IP: 10.64.148.20

### 1. Go to the folder of Nanopore analysis, which is named `xxhps`, e.g. 24hps
<img width="955" height="255" alt="image" src="https://github.com/user-attachments/assets/a80635f8-3df1-436f-bd1f-6b60fe1d2c5a" />

### 2. Copy the script `run_Extract_reads.sh` to the `xxhps` folder
Or you can open the `xxhps` folder in terminal and type command: 
```
cp /media/kt_jdip/Data_Drive/KT_shared_mNGS_Scripts/run_Extract_reads.sh .
```
### 3. Modify `run_Extract_reads.sh`
<img width="673" height="132" alt="image" src="https://github.com/user-attachments/assets/51d41e75-f601-42d7-9a6b-f1a19d76cd98" />

> [!NOTE]
> - You need to change:
> - **--species:**       e.g. specify "Mycobacterium xenopi" instead of "Mycobacterium", might fail to extract genus reads
> - **--fastq:**         e.g. nohuman_barcode03.fastq.gz, specify the nohuman fastq file of targeted barcode
> - **--run_assembly:**  yes or no, depends on whether you want to do assembly for the extracted reads

### 4. Run task
Command line: `bash run_Extract_reads.sh` and you will see the output:
```
├── nohuman_barcode03_Legionella_pneumophila_taxid446_flye_assembly_20260106-1610
│   ├── assembly.fasta                                                <-------- the assembly FASTA file generated from species
│   ├── ...
│   └── params.json
├── nohuman_barcode03_Legionella_pneumophila_taxid446_readsID.fasta   <-------- the species FASTA file
├── nohuman_barcode03_Legionella_pneumophila_taxid446_readsID.fastq   <-------- the species FASTQ file
├── nohuman_barcode03_Legionella_pneumophila_taxid446_readsID.txt
```
<img width="1045" height="663" alt="image" src="https://github.com/user-attachments/assets/d1023689-df2e-4850-a2f5-acaf774a36e9" />
