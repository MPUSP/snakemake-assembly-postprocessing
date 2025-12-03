# import basic packages
import pandas as pd
from snakemake.utils import validate


# read sample sheet
samples = (
    pd.read_csv(config["samplesheet"], sep=",", dtype={"sample": str})
    .set_index("sample", drop=False)
    .sort_index()
)

# validate sample sheet and config file
validate(samples, schema="../../config/schemas/samples.schema.yml")
validate(config, schema="../../config/schemas/config.schema.yml")


# -----------------------------------------------------
# input functions
# -----------------------------------------------------
def get_fasta(wildcards):
    """Get the fasta file for the sample."""
    sample = wildcards.sample
    if sample not in samples.index:
        raise ValueError(f"Sample {sample} not found in samplesheet.")

    # return the fasta file path
    return samples.loc[sample, "file"]
