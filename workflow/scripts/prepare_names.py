# PREPARE NTSYNT-VIZ NAME MAPPING
# -----------------------------------------------------------------------------
#
# This script maps sample names to the names to be used in
# ntSynt-viz.

import os
import sys
import pandas as pd

sys.stderr = open(snakemake.log[0], "w", buffering=1)
sample_sheet = snakemake.params["sample_sheet"]
outfile = snakemake.output[0]
ref = snakemake.params["ref"]

# read sample sheet
try:
    df_samples = pd.read_csv(sample_sheet)
    sys.stderr.write(f"Read sample sheet from {snakemake.params['sample_sheet']}\n")
except Exception as e:
    sys.stderr.write(
        f"Error reading sample sheet from {snakemake.params['sample_sheet']}: {e}\n"
    )

df_samples["file"] = df_samples["file"].apply(lambda x: os.path.basename(x))

# add reference if provided
if ref:
    ref_file, ref_name = ref
    df_ref = pd.DataFrame({"file": [os.path.basename(ref_file)], "sample": [ref_name] if ref_name else [os.path.basename(ref_file)]})
    df_samples = pd.concat([df_samples, df_ref], ignore_index=True)

# ntSynt mutates "_" to " "
df_samples["sample"] = df_samples["sample"].apply(lambda x: x.replace("_", "-").replace(" ", "_"))

try:
    df_samples[["file", "sample"]].to_csv(outfile, sep="\t", index=False, header=False)
    sys.stderr.write(f"Wrote ntSynt-viz sample name mapping to {outfile}\n")
except Exception as e:
    sys.stderr.write(
        f"Error writing ntSynt-viz sample name mapping to {outfile}: {e}\n"
    )
