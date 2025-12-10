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
| ...    | ...                      | ...    | ...       | ...            |

**Note:** Pangenome analysis with `Panaroo` requires at least two samples.

### Parameters

This table lists all parameters that can be used to run the workflow.

| Parameter | Type | Details | Default |
|:---|:---|:---|:---|
| **samplesheet** | string | Path to the sample sheet file in csv format | |
| **tool** | array[string] | Annotation tool to use (one of `prokka`, `pgap`, `bakta`) | |
| **pgap** | | PGAP configuration object |  |
| bin | string | Path to the PGAP script | |
| use_yaml_config | boolean | Whether to use YAML configuration for PGAP | `False` |
| _prepare_yaml_files_ | | Paths to YAML templates for PGAP | |
| generic | string | Path to the generic YAML configuration file | |
| submol | string | Path to the submol YAML configuration file | |
| **prokka** | | Prokka configuration object | |
| center | string | Center name for Prokka annotation (used in sequence IDs) | |
| extra | string | Extra command-line arguments for Prokka | |
| **bakta** | | Bakta configuration object | |
| download_db | string | Bakta database type (`full`, `light`, or `none`) | `light` |
| existing_db | string | Path to an existing Bakta database (optional). Needs to be combined with `download_db='none'` | |
| extra | string | Extra command-line arguments for Bakta | |
| **quast** | | QUAST configuration object | |
| reference_fasta | string | Path to the reference genome for QUAST | |
| reference_gff | string | Path to the reference annotation for QUAST |
| extra | string | Extra command-line arguments for QUAST | |
| **panaroo** | | Panaroo configuration object | |
| remove_source | string | Source types to remove in Panaroo (regex supported) | `cmsearch` |
| remove_feature | string | Feature types to remove in Panaroo (regex supported) | `tRNA\|rRNA\|ncRNA\|exon\|sequence_feature` |
| extra | string | Extra command-line arguments for Panaroo | |
