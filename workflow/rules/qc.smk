rule quast:
    input:
        fasta=get_quast_fasta,
    output:
        report="results/qc/quast/{tool}/report.txt",
    log:
        "results/qc/quast/{tool}/quast.log",
    conda:
        "../envs/quast.yml"
    threads: 4
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
    message:
        """--- Running QUAST quality check for all assemblies ---"""
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


rule prepare_panaroo:
    input:
        fasta="results/annotation/{tool}/{sample}/{sample}.fna",
        gff="results/annotation/{tool}/{sample}/{sample}.gff",
    output:
        fasta="results/qc/panaroo/{tool}/prepare/{sample}.fna",
        gff="results/qc/panaroo/{tool}/prepare/{sample}.gff",
    log:
        "results/qc/panaroo/{tool}/prepare/{sample}.log",
    conda:
        "../envs/panaroo.yml"
    params:
        remove_source=config["panaroo"]["remove_source"],
        remove_feature=config["panaroo"]["remove_feature"],
    message:
        """--- Prepare input files for pan-genome alignment ---"""
    shell:
        """
        echo 'Preparing annotation for Panaroo:' > {log};
        echo '  - formatting seqnames in FASTA files' >> {log};
        awk '{{ sub(/>.*\\|/, ">"); sub(/[[:space:]].*$/, ""); print }}' \
          {input.fasta} > {output.fasta} 2>> {log};
        echo '  - removing sequences and selected features in GFF files' >> {log};
        awk ' /^##FASTA/ {{exit}} $2 !~ /{params.remove_source}/ && $3 !~ /{params.remove_feature}/ {{print}}' \
          {input.gff} > {output.gff} 2>> {log}
        """


rule panaroo:
    input:
        gff=get_panaroo_gff,
        fasta=get_panaroo_fasta,
    output:
        stats="results/qc/panaroo/{tool}/summary_statistics.txt",
    log:
        "results/qc/panaroo/{tool}/panaroo.log",
    conda:
        "../envs/panaroo.yml"
    threads: 4
    params:
        outdir=lambda wc, output: os.path.dirname(output.stats),
        extra=config["panaroo"]["extra"],
    message:
        """--- Running PANAROO to create pangenome from all annotations ---"""
    shell:
        """
        printf '%s\n' {input.gff} | \
          paste -d ' ' - <(printf '%s\n' {input.fasta}) \
          > {params.outdir}/input_files.txt;
        panaroo \
          -i {params.outdir}/input_files.txt \
          -o {params.outdir} \
          -t {threads} \
          {params.extra} \
          > {log} 2>&1
        """
