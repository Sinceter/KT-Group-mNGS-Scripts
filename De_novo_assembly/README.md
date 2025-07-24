# De novo assembly scripts
The scripts are stored in CVVT server.

### Megahit for short reads assembly:

```bash
/home/kelvinto/kelvinto/aixin/z.05.Jonathan.BAL.samples/step2.megahit.sh
```

### Flye for long reads assembly:

```bash
/home/kelvinto/kelvinto/aixin/z.05.Jonathan.BAL.samples/step2.flye.sh
```

# 1. copy target script to your working directory
- Megahit
```bash
cp /home/kelvinto/kelvinto/aixin/z.05.Jonathan.BAL.samples/step2.megahit.sh <your working directory>
```
- Flye
```bash
cp /home/kelvinto/kelvinto/aixin/z.05.Jonathan.BAL.samples/step2.flye.sh <your working directory>
```

# 2. usage
```
bash <target script> <fastq file>
```

# 3. output
- Megahit output folder
```
megahit_${prefix_name_of_your_fastq_file}_${date}
```
- The assembled contigs from Megahit are stored in:
```
megahit_${prefix_name_of_your_fastq_file}_${date}/final.contigs.fa
```

- Flye output folder
```
flye_${prefix_name_of_your_fastq_file}_${date}
```
- The assembled contigs from Flye are stored in:
```
flye_${prefix_name_of_your_fastq_file}_${date}/assembly.fasta
```
