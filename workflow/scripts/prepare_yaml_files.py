__author__ = "Rina Ahmed-Begrich"
__copyright__ = "Copyright 2025, Rina Ahmed-Begrich"
__license__ = "MIT"
__annotations__ = "script to prepare input yaml files for pgap"


import os
import sys
import yaml

sys.stderr = open(snakemake.log[0], "w", buffering=1)
sample = snakemake.params["sample"]
fasta = snakemake.input["fasta"]
input_yaml = snakemake.output["input_yaml"]
submol_yaml = snakemake.output["submol_yaml"]
organism = snakemake.params["organism"]
locus_tag = snakemake.params["locus_tag"]
generic_template = snakemake.params["generic"]
submol_template = snakemake.params["submol"]
samples = snakemake.params["pd_samples"]


# define helper functions
def read_yaml_to_dict(filepath: str) -> None:
    try:
        with open(filepath, "r") as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        sys.stderr.write(f"File not found: {filepath}\n")
    except yaml.YAMLError as e:
        sys.stderr.write(f"YAML error in {filepath}: {e}\n")
    except Exception as e:
        sys.stderr.write(f"Unexpected error reading {filepath}: {e}\n")
    sys.stderr.write(f"Read YAML file: {filepath}")
    return None


def write_dict_to_yaml(outdict: dict, filepath: str) -> None:
    try:
        with open(filepath, "w") as f:
            yaml.safe_dump(outdict, f, default_flow_style=False)
        sys.stderr.write(f"Wrote YAML file: {filepath}\n")
    except Exception as e:
        sys.stderr.write(f"Error writing YAML file {filepath}: {e}\n")


generic_dict = read_yaml_to_dict(generic_template)
submol_dict = read_yaml_to_dict(submol_template)

generic_dict["fasta"]["location"] = os.path.abspath(fasta)
generic_dict["submol"]["location"] = os.path.abspath(submol_yaml)

if not organism:
    organism = samples.loc[sample]["species"]

submol_dict["organism"]["genus_species"] = organism
submol_dict["organism"]["strain"] = samples.loc[sample]["strain"]

if not locus_tag:
    locus_tag = "Spy"
submol_dict["locus_tag_prefix"] = locus_tag

write_dict_to_yaml(generic_dict, input_yaml)
write_dict_to_yaml(submol_dict, submol_yaml)
sys.stderr.write(f"Module 'prepare yaml files' finished successfully!")
