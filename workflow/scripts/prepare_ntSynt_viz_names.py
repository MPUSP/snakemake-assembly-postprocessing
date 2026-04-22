# PREPARE NTSYNT-VIZ NAME MAPPING
# -----------------------------------------------------------------------------
#
# This script prepares a mapping of sample names to the names to be used in
# ntSynt-viz. This is needed to ensure that the sample names in the ntSynt-viz
# ribbon plot are the same as the sample names in the sample sheet.

import os
import sys
import pandas as pd

sys.stderr = open(snakemake.log[0], "w", buffering=1)
sample_sheet = snakemake.params["sample_sheet"]
outfile = snakemake.output[0]

# read sample sheet
try:
    df_samples = pd.read_csv(sample_sheet)
    sys.stderr.write(f"Read sample sheet from {snakemake.params['sample_sheet']}\n")
except Exception as e:
    sys.stderr.write(
        f"Error reading sample sheet from {snakemake.params['sample_sheet']}: {e}\n"
    )

df_samples["file"] = df_samples["file"].apply(lambda x: os.path.basename(x))

try:
    df_samples[["file", "sample"]].to_csv(outfile, sep="\t", index=False, header=False)
    sys.stderr.write(f"Wrote ntSynt-viz sample name mapping to {outfile}\n")
except Exception as e:
    sys.stderr.write(
        f"Error writing ntSynt-viz sample name mapping to {outfile}: {e}\n"
    )
