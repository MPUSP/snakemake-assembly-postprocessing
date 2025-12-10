## Workflow overview

A Snakemake workflow for the post-processing of microbial genome assemblies.

1. Parse `samples.csv` table containing the samples's meta data (`python`)
2. Annotate assemblies using one of the following tools:
   1. NCBI's Prokaryotic Genome Annotation Pipeline ([PGAP](https://github.com/ncbi/pgap)). Note: needs to be installed manually
   2. [prokka](https://github.com/tseemann/prokka), a fast and light-weight prokaryotic annotation tool
   3. [bakta](https://github.com/oschwengers/bakta), a fast, alignment-free annotation tool. Note: Bakta will automatically download its companion database from zenodo (light: 1.5 GB, full: 40 GB)
3. Create a QC report for the assemblies using [Quast](https://github.com/ablab/quast)
4. Create a pangenome analysis (orthologs/homologs) using [Panaroo](https://gthlab.au/panaroo/)

## Installation

**Step 1: Clone this repository**

```bash
git clone https://github.com/MPUSP/snakemake-assembly-postprocessing.git
cd snakemake-assembly-postprocessing
```

**Step 2: Install dependencies**

It is recommended to install snakemake and run the workflow with `conda` or `mamba`. [Miniforge](https://conda-forge.org/download/) is the preferred conda-forge installer and includes `conda`, `mamba` and their dependencies.

**Step 3: Create snakemake environment**

This step creates a new conda environment called `snakemake-assembly-postprocessing`.

```bash
mamba create -c conda-forge -c bioconda -n snakemake-assembly-postprocessing snakemake pandas
conda activate snakemake-assembly-postprocessing
```

**Step 4: Install PGAP**

- if you want to use [PGAP](https://github.com/ncbi/pgap) for annotation, it needs to be installed separately
- PGAP can be downloaded from https://github.com/ncbi/pgap. Please follow the installation instructions there.
- Define the path to the `pgap.py` script (located in the `scripts` folder) in the `config` file (recommended: `./resources`)

## Running the workflow

### Input data

This workflow requires `fasta` input data.
The samplesheet table has the following layout:

| sample | species                  | strain | id_prefix | file           |
| ------ | ------------------------ | ------ | --------- | -------------- |
| EC2224 | "Streptococcus pyogenes" | SF370  | SPY       | assembly.fasta |
