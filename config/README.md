## Running the workflow

### Input data

This workflow requires `fasta` input data.
The samplesheet table has the following layout:

| sample | species | strain | id_prefix | file |
| ----------- | ------------ | ------------- | ------------- | ------------- |
| EC2224 | "Streptococcus pyogenes" | SF370 | Spy | assembly.fasta |

### Execution

To run the workflow from command line, change to the working directory and activate the conda environment.

```bash
cd snakemake-assembly-postprocessing
conda activate snakemake-assembly-postprocessing
```

Adjust options in the default config file `config/config.yml`.
Before running the entire workflow, perform a dry run using:

```bash
snakemake --cores 1 --sdm conda --directory .test --dry-run
```

To run the workflow with test files using **conda**:

```bash
snakemake --cores 1 --sdm conda --directory .test
```
