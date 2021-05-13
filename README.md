###########################
THIS PROJECT IS UNDER DEVELOPMENT
###########################

### Using Singularity (HPC / machines without root privileges / CC)

#### Installation
**1** - download and build a local singularity image for typeref
```sh=
singularity pull --name clemgoub-typeref-latest.img docker://clemgoub/typeref:latest
```
**2** - clone `Type-REF` from GitHub
```shell=
git clone --recurse-submodule https://github.com/clemgoub/typeref
```
**3** - mofify the nextflow.config file as follow:
```
singularity.enabled = true
process.container = '<your-path>/clemgoub-typeref-latest.img'
singularity.autoMounts = true
```
This way, their is no root or internet requirement for a typeref run.

#### Running TypeREF on CC (HPC)
So far we will run TypeREF using an interactive job request (vs. using a `SBATCH` file)

**1** - load the necessary modules
```shell=
module load singularity
module load nextflow
```

**2** - latest "test" command
```shell=
nextflow run typeref/TypeREF.nf \
--meltvcf non_git_data/KIMs_DEL.chr22.vcf.recode.vcf \
--ref non_git_data/hg38.simple.fasta \
--RM_track typeref/Ressources/RepeatMasker_Alu_hg38.bed \
--aln_samples /project/def-bourqueg/cgoubert/pr-TypeREF/data-TEST/all.chr.cram.txt \
--outdir /project/def-bourqueg/cgoubert/pr-TypeREF \
--aln_path /project/def-bourqueg/cgoubert/pr-TypeREF/data-TEST
```