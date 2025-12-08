rule quast:
    input:
        fasta=get_quast_fasta,
        gff=get_quast_gff,
    output:
        report="results/qc/quast/{tool}/report.txt",
    conda:
        "../envs/quast.yml"
    message:
        """--- Running QUAST quality check for all assemblies ---"""
    params:
        outdir=lambda wc, output: os.path.dirname(output.report),
        ref=(
            " ".join(["-r", config["quast"]["reference"]])
            if config["quast"]["reference"]
            else []
        ),
        extra=config["quast"]["extra"],
    threads: workflow.cores * 0.25
    log:
        "results/qc/quast/{tool}/quast.log",
    shell:
        """
        quast \
        --output-dir {params.outdir} \
        --threads {threads} \
        --features {input.gff} \
        {params.ref} \
        {params.extra} \
        {input.fasta} \
        > {log} 2>&1
        """
