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
    return samples.loc[sample, "file"]


def get_quast_fasta(wildcards):
    return expand(
        "results/annotation/{tool}/{sample}/{sample}.fna",
        tool=wildcards.tool,
        sample=samples.index,
    )


def get_panaroo_gff(wildcards):
    return expand(
        "results/qc/panaroo/{tool}/prepare/{sample}.gff",
        tool=wildcards.tool,
        sample=samples.index,
    )


def get_panaroo_fasta(wildcards):
    return expand(
        "results/qc/panaroo/{tool}/prepare/{sample}.fna",
        tool=wildcards.tool,
        sample=samples.index,
    )


def get_final_input(wildcards):
    inputs = []
    inputs += expand(
        "results/qc/quast/{tool}/report.txt",
        tool=config["tool"],
    )
    if len(samples.index) > 1:
        inputs += expand(
            "results/qc/panaroo/{tool}/summary_statistics.txt",
            tool=config["tool"],
        )
    return inputs
