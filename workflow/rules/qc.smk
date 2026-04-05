rule quast:
    input:
        fasta=get_all_fasta,
    output:
        report="results/qc/quast/report.txt",
    log:
        "results/qc/quast/quast.log",
    conda:
        "../envs/quast.yml"
    threads: max(workflow.cores * 0.5, 1)
    params:
        outdir=lambda wc, output: os.path.dirname(output.report),
        ref_fasta=(
            " ".join(["-r", config["reference"]["fasta"]])
            if config["reference"]["fasta"]
            else []
        ),
        ref_gff=(
            " ".join(["-g", config["reference"]["gff"]])
            if config["reference"]["gff"]
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


rule fastani:
    input:
        fasta=get_all_fasta,
    output:
        txt="results/qc/fastani/summary.txt",
    log:
        "results/qc/fastani/fastani.log",
    conda:
        "../envs/fastani.yml"
    threads: max(workflow.cores * 0.5, 1)
    params:
        outdir=lambda wc, output: os.path.dirname(output.txt),
        ref_fasta=(
            [config["reference"]["fasta"]] if config["reference"]["fasta"] else []
        ),
        extra=config["fastani"]["extra"],
    message:
        """--- Running FastANI to compare genome similarity (all vs all) ---"""
    shell:
        """
        printf '%s\n' {input.fasta} > {params.outdir}/input_files.txt;
        printf '%s\n' {params.ref_fasta} >> {params.outdir}/input_files.txt;
        fastANI \
          --ql {params.outdir}/input_files.txt \
          --rl {params.outdir}/input_files.txt \
          --output {output.txt} \
          --threads {threads} \
          {params.extra} \
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
    threads: max(workflow.cores * 0.5, 1)
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
