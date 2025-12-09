rule quast:
    input:
        fasta=get_quast_fasta,
    output:
        report="results/qc/quast/{tool}/report.txt",
    conda:
        "../envs/quast.yml"
    message:
        """--- Running QUAST quality check for all assemblies ---"""
    params:
        outdir=lambda wc, output: os.path.dirname(output.report),
        ref_fasta=(
            " ".join(["-r", config["quast"]["reference_fasta"]])
            if config["quast"]["reference_fasta"]
            else []
        ),
        ref_gff=(
            " ".join(["-g", config["quast"]["reference_gff"]])
            if config["quast"]["reference_gff"]
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
        {params.ref_fasta} \
        {params.ref_gff} \
        {params.extra} \
        {input.fasta} \
        > {log} 2>&1
        """
