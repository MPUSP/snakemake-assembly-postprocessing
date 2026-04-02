# import basic packages
import pandas as pd
import re
from snakemake import logging
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


def get_all_fasta(wildcards):
    """Get all input fasta files for all samples."""
    return [samples.loc[s, "file"] for s in samples.index]


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
        "results/qc/quast/report.txt",
    )
    if len(samples.index) > 1 and not config["panaroo"]["skip"]:
        inputs += expand(
            "results/qc/panaroo/{tool}/summary_statistics.txt",
            tool=config["tool"],
        )
    if len(samples.index) > 1 and not config["fastani"]["skip"]:
        inputs += expand(
            "results/qc/fastani/summary.txt",
        )
    return inputs


# -----------------------------------------------------
# helper functions
# -----------------------------------------------------
def format_bakta_locustag(raw):
    """Format locustag for BAKTA annotation."""
    tag = str(raw)
    # uppercase for BAKTA
    tag_up = tag.upper()
    # keep only A-Z0-9
    cleaned = re.sub(r"[^A-Z0-9]", "", tag_up)
    if len(cleaned) < 3 or len(cleaned) > 12:
        raise ValueError(
            f"locustag '{raw}' -> '{cleaned}' must contain between 3-12 alphanumeric uppercase characters\n"
        )
    if not re.match(r"^[A-Z]", cleaned):
        raise ValueError(f"locustag '{raw}' -> '{cleaned}' must start with a letter")
    # warn if cleaned tag is different from original
    if cleaned != tag:
        logger.warning(
            f"\nlocustag '{raw}' converted to '{cleaned}' to meet BAKTA requirements (between 3 and 12 alphanumeric uppercase characters, start with a letter)\n"
        )
    return cleaned
