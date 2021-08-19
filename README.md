[![status](https://img.shields.io/badge/status:-dev-red)]() [![status: support](https://img.shields.io/badge/support:-no-red)]()

🏗️ PROJECT UNDER DEVELOPMENT 🚧
- Migration of Type-TE to Nextflow pipeline
- Reference insertions only (see MELT2 and xTEA for non-reference insertions)
- Alu, L1 and SVA genotyping

# TypeREF Manual (dev version)
###### tags: `TypeREF` `Documentation`

## Warning
This version is under active developments. Results can be incorrect and some feature not working.
- Alu and SVA: OK to test
- LINE1: **not ready**

## Overview 
TypeREF is a program to genotype "reference" mobile elements insertions, namely **AluY**, **LINE1** and **SVA** retrotransposons.

For genotyping of non-reference insertions see [MELT2](https://melt.igs.umaryland.edu) or [xTEA](https://github.com/parklab/xTea).
For Endogeneous Retrovirus polymorphism see: [RetroSeq](https://github.com/tk2/RetroSeq), [ERVcaller](https://academic.oup.com/bioinformatics/article/35/20/3913/5416145?login=true) and [dimorphicERV](https://github.com/jainy/dimorphicERV)

![](https://i.imgur.com/AyeSv8x.png)

## Install

### 1. Clone TypeREF repos

The Type-REF project is hosted on github and is available for download
   
```shell=
git clone https://github.com/clemgoub/typeref.git
```

### 2. Build the Singularity image

With every update of the `Dockerfile`, a new `docker` image is pushed to [Docker-hub](https://hub.docker.com/r/clemgoub/typeref). This way, the `docker` image can directly downloaded and converted to a `singularity` image for rootless users (such as Calcul Canada [CC]) and cannot use `docker`.

```shell=
singularity pull --name clemgoub-typeref-latest.img docker://clemgoub/typeref:latest
```
> *building the image with `singularity pull` is slow, but only required once*

### 3. Configure Nextflow

Open and mofify the `nextflow.config` file, located in the `TypeREF` repository as follow:

```
singularity.enabled = true
process.container = '<your-path>/clemgoub-typeref-latest.img'
singularity.autoMounts = true
```

## Running TypeREF

### 1. Input files

- **vcf**, for example from MELT "deletion" OR **bed** file with Reference TE coordinates `--meltvcf`/`--bed`

    #### Example 1: `.vcf`

    ```
    #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	PPMISI3658	PPMISI3666	PPMISI3966	PPMISI4110
    chr22	10673619	.	C	<CN:0>	.	.	SVTYPE=AluYi6;END=10673927;SVLEN=308;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/0:-1.81,-13.25,-213.51	0/1:-90.1,-8.43,-48.16	0/0:-5.42,-9.63,-87.22	0/1:-39.7,-7.22,-82.03
    chr22	16159229	.	A	<CN:0>	.	.	SVTYPE=AluY;END=16159526;SVLEN=297;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/1:-132,-19.87,-241.1	0/0:-0,-13.85,-254.5	0/0:-0,-13.25,-236.2	0/1:-108,-13.85,-160.8
    chr22	17091394	.	T	<CN:0>	.	.	SVTYPE=AluY;END=17091689;SVLEN=295;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/0:-0,-16.26,-308.9	0/0:-0,-18.66,-346.1	0/0:-0.01,-12.64,-217.9	0/1:-192,-13.85,-84
    chr22	21558350	.	T	<CN:0>	.	.	SVTYPE=AluY;END=21558649;SVLEN=299;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/0:-5.42,-24.08,-330.52	0/1:-108,-8.43,-60	0/0:-0.02,-14.45,-244.6	1/1:-109.2,-6.62,-1.2
    chr22	22560568	.	C	<CN:0>	.	.	SVTYPE=AluY;END=22560869;SVLEN=301;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/1:-171.6,-33.72,-485.33	0/1:-76.4,-27.09,-456.01	0/1:-144.7,-24.08,-324.02	0/1:-84,-18.66,-288
    chr22	26052795	.	G	<CN:0>	.	.	SVTYPE=AluY;END=26053106;SVLEN=311;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/0:-0,-10.84,-193.2	0/1:-120,-9.63,-68	0/0:-0,-6.62,-119	0/1:-132,-8.43,-36
    chr22	31648396	.	G	<CN:0>	.	.	SVTYPE=AluYc;END=31648685;SVLEN=289;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/1:-168,-15.05,-132	0/0:-1.2,-18.06,-322.2	0/1:-216,-13.85,-60	0/1:-240,-15.65,-72
    chr22	39417338	.	A	<CN:0>	.	.	SVTYPE=AluY;END=39417641;SVLEN=303;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/1:-72,-12.64,-173	0/0:-0.09,-16.26,-272.3	0/0:-0,-13.85,-253.7	0/0:-0,-12.64,-228.1
    chr22	41089698	.	C	<CN:0>	.	.	SVTYPE=AluY;END=41089996;SVLEN=298;ADJLEFT=0;ADJRIGHT=0	GT:GL	0/1:-95,-15.65,-207.2	0/1:-153.4,-15.05,-142.3	0/1:-72,-15.65,-227.6	0/0:-1.2,-7.83,-121.1
    ```
    >`.vcf` file from MELT2 "deletion" pipeline. Minimal header.

   
   #### Example 2: `.bed`

    ```
    chr5	166877891	166878111	AluYk3	SINE/Alu	+
    chr20	45108615	45108923	AluY	SINE/Alu	C
    chr11	134147494	134147785	AluY	SINE/Alu	C
    chr10	102827093	102827390	AluY	SINE/Alu	C
    chr13	82026280	82026561	AluY	SINE/Alu	C
    chr15	30684990	30685283	AluYe5	SINE/Alu	+
    chr10	47510937	47511242	AluY	SINE/Alu	C
    chr8	145009005	145009305	AluYf1	SINE/Alu	+
    chr3	51475580	51475874	AluY	SINE/Alu	+
    chr4	148568483	148568788	AluY	SINE/Alu	+
    chr19	40498364	40498703	AluY	SINE/Alu	C
    ```
    > RepeatMasker track filtered for *AluY* elements

- **Reference genome** `--ref`: best to use the same file used in the original alignment.

- **sample list** `--aln_sample`: tab delimited, 2 columns with header

    ```
    sampleId    fileId
    NA07056    NA07056.mapped.ILLUMINA.bwa.CEU.low_coverage.20101123.bam
    NA11830    NA11830.mapped.ILLUMINA.bwa.CEU.low_coverage.20101123.bam
    NA12144    NA12144.mapped.ILLUMINA.bwa.CEU.low_coverage.20101123.bam
    ```

- **sample path** `--aln_path`
Location of the actual `.bam/.cram` and their indices (`.bai/.crai`) are located (path to folder).

- **Repeat Masker track** (provided)
RepeatMasker tracks for Alu, L1 and SVA are available for hg19 and hg38 in the folder `./typeref/Ressources/RepeatMasker_*_hg*.bed`

### 2. Requirement

- cpu: **up to 1 per sample**. Two steps are parallelized and Nextflow will use the available cpus to run these steps in parallel: 
    - allele indexing (`insgen_indexAlleles`: by batches of 8 loci at a time)
    - genotyping (`insgen_Genotype`: by individual). 
- memory: **<1Gb** per cpu

*The following examples are for ~10 loci and 3 individuals*

### 3. Command line arguments
```
Input:
  --meltvcf       vcf/vcf.gz file preduced by MELT-DEL pipeline (Deletion-Merge command)
  or
  --bed           bed file with Reference TE coordinates/breakpoint

  --ref           reference genome used with the short-reads aligner (.fasta)
  --RM_track      RepeatMasker track for reference MEI (.bed) 
                  note: RM track for hg19 and hg38 are available in the "Ressources" folder
  --aln_path      path to bam/cram directory (all samples need to be in the same directory however, 
                  the files to analyse will be only those in the aln_samples table)
  --aln_samples   two columns (tab delimited) with samples ID in column 1 and associated samples file names (.bam/.cram) in column 2. 
                  ex: NA12878  NA12878.project.blah.bam
                      NA12831  NA12831.project.blah.bam
Output:
  --outdir        output directory to store results
  
Options:
  --TE            TE type to be genotyped: Alu | SVA | LINE1[not tested] (default: Alu)
  --help          this message
```

## Tips / Checklist

- Nextflow and Singularity modules nead to be loaded
- As much as possible, use the exact same reference genome than used for read alignment
- Input only loci of one type of TE at a time (Alu[Y*], SVA[A/B/C/D/E/F] or L1)
- Check that your input (vcf of bed) has the same contig/chromosome names the same format than the refernce genome. Most frequent error is the presence or not of the string `chr` between versions. Provided repeat tracks are compatible with both formats.
- Erasing the `work/` folder produced by Nextflow can resolve some issues
- An interupted job can be resumed if the `work` folder is saved. Use the `-resume` option (only one `-`)


## Notes

- Paralelized steps should automaticaly use all available CPUs, but this feature hasn't been tested yet
