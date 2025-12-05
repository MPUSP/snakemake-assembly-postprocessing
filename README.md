# snakemake-assembly-postprocessing

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.24.1-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/MPUSP/snakemake-assembly-postprocessing/actions/workflows/main.yml/badge.svg)](https://github.com/MPUSP/snakemake-assembly-postprocessing/actions/workflows/main.yml)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with apptainer](https://img.shields.io/badge/run%20with-apptainer-1D355C.svg?labelColor=000000)](https://apptainer.org/)

A Snakemake workflow for the post-processing of microbial genome assemblies.

## Usage

The usage of this workflow is described in the [Snakemake Workflow Catalog](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/MPUSP/snakemake-assembly-postprocessing).

If you use this workflow in a paper, don't forget to give credits to the authors by citing the URL of this repository.

## Workflow overview

1. Parse `samples.csv` table containing the samples's meta data (`python`)
2. Annotate assemblies using one of the following tools:
   1. NCBI's Prokaryotic Genome Annotation Pipeline ([PGAP](https://github.com/ncbi/pgap)). Note: needs to be installed manually
   2. [prokka](https://github.com/tseemann/prokka), a fast and light-weight prokaryotic annotation tool
   3. [bakta](https://github.com/oschwengers/bakta), a fast, alignment-free annotation tool. Note: Bakta will automatically download its companion database from zenodo (light: 1.5 GB, full: 40 GB)

## Requirements

- [PGAP](https://github.com/ncbi/pgap)

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

- PGAP can be downloaded from https://github.com/ncbi/pgap. Please follow the installation instructions there.
- Define the path to the `pgap.py` script (located in the `scripts` folder) in the `config` file (recommended: `./resources`)

## Authors

- Dr. Rina Ahmed-Begrich
  - Affiliation: [Max-Planck-Unit for the Science of Pathogens](https://www.mpusp.mpg.de/) (MPUSP), Berlin, Germany
  - ORCID profile: https://orcid.org/0000-0002-0656-1795
- Dr. Michael Jahn
  - Affiliation: [Max-Planck-Unit for the Science of Pathogens](https://www.mpusp.mpg.de/) (MPUSP), Berlin, Germany
  - ORCID profile: https://orcid.org/0000-0002-3913-153X
  - github page: https://github.com/m-jahn

## References

> Li W, O'Neill KR, Haft DH, DiCuccio M, Chetvernin V, Badretdin A, Coulouris G, Chitsaz F, Derbyshire MK, Durkin AS, Gonzales NR, Gwadz M, Lanczycki CJ, Song JS, Thanki N, Wang J, Yamashita RA, Yang M, Zheng C, Marchler-Bauer A, Thibaud-Nissen F. _RefSeq: Expanding the Prokaryotic Genome Annotation Pipeline reach with protein family model curation._ Nucleic Acids Res, **2021** Jan 8;49(D1):D1020-D1028. https://doi.org/10.1093/nar/gkaa1105

> Köster, J., Mölder, F., Jablonski, K. P., Letcher, B., Hall, M. B., Tomkins-Tinch, C. H., Sochat, V., Forster, J., Lee, S., Twardziok, S. O., Kanitz, A., Wilm, A., Holtgrewe, M., Rahmann, S., & Nahnsen, S. _Sustainable data analysis with Snakemake_. F1000Research, 10:33, 10, 33, **2021**. https://doi.org/10.12688/f1000research.29032.2.
