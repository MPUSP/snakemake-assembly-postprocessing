## Workflow overview

A Snakemake workflow for the post-processing of microbial genome assemblies.

1. Parse `samples.csv` table containing the samples's meta data (`python`)
2. Annotate assemblies using one of the following tools:
   1. NCBI's Prokaryotic Genome Annotation Pipeline ([PGAP](https://github.com/ncbi/pgap)). Note: needs to be installed manually
   2. [prokka](https://github.com/tseemann/prokka), a fast and light-weight prokaryotic annotation tool
   3. [bakta](https://github.com/oschwengers/bakta), a fast, alignment-free annotation tool. Note: Bakta will automatically download its companion database from zenodo (light: 1.5 GB, full: 40 GB)
3. Create a QC report for the assemblies using [Quast](https://github.com/ablab/quast)
4. Create a pangenome analysis (orthologs/homologs) using [Panaroo](https://gthlab.au/panaroo/)

## Running the workflow

### Input data

This workflow requires `fasta` input data.
The samplesheet table has the following layout:

| sample | species                  | strain | id_prefix | file           |
| ------ | ------------------------ | ------ | --------- | -------------- |
| EC2224 | "Streptococcus pyogenes" | SF370  | SPY       | assembly.fasta |

**Note:** Pangenome analysis with `Panaroo` requires at least two samples.