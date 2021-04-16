###
in construction
###

### Singularity (HPC / machines without root privileges)

1 - download and build a local singularity image for typeref
```
singularity pull --name clemgoub-typeref-latest.img docker://clemgoub/typeref:latest
```

2 - mofify the nextflow.config file as follow:
```
singularity.enabled = true
process.container = '<your-path>/clemgoub-typeref-latest.img'
singularity.autoMounts = true
```
This way, their is no root or internet requirement for a typeref run.