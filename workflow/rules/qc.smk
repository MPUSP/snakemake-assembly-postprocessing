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
            >{log} 2>&1
        """


rule get_ceckm_db:
    output:
        db="results/qc/checkm/database/uniref100.KO.1.dmnd",
    log:
        "results/qc/checkm/logs/db.log",
    conda:
        "../envs/checkm.yml"
    params:
        existing_db=config["checkm"]["existing_db"],
        outdir=lambda wc, output: os.path.dirname(output[0]),
    message:
        """--- Getting CheckM database ---"""
    shell:
        """
        if [ -n "{params.existing_db}" ]; then
            echo 'Using supplied CheckM DB from: {params.existing_db}' >{log}
            ln -s {params.existing_db} {output.db}
        else
            echo "The most recent checkM DB will be downloaded..." >{log}
            checkm2 database --download --path {params.outdir} &>>{log}
            ln -s {params.outdir}/CheckM2_database/uniref100.KO.1.dmnd {output.db}
        fi
        """


rule checkm:
    input:
        fasta=get_all_fasta,
        db=rules.get_ceckm_db.output.db,
    output:
        tsv="results/qc/checkm/predicted/quality_report.tsv",
    log:
        "results/qc/checkm/logs/checkm.log",
    conda:
        "../envs/checkm.yml"
    threads: max(workflow.cores * 0.5, 1)
    params:
        outdir=lambda wc, output: os.path.dirname(output.tsv),
        extra=config["checkm"]["extra"],
    message:
        """--- Running CheckM to assess genome completeness and contamination ---"""
    shell:
        """
        checkm2 predict \
            --threads {threads} \
            --input {input.fasta} \
            --database_path {input.db} \
            --output-directory {params.outdir} \
            --force \
            {params.extra} \
            &>{log}
        rm -f {params.outdir}/checkm2.log
        """


rule rgi_detection:
    input:
        fasta=get_fasta,
    output:
        multiext("results/rgi/{sample}/result", ".txt", ".json"),
    log:
        "results/rgi/{sample}/result.log",
    threads: max(workflow.cores * 0.25, 1)
    params:
        input_type="contig",
        extra=config["rgi"]["extra"],
    message:
        """--- Running RGI to detect antibiotic resistance genes ---"""
    wrapper:
        "https://raw.githubusercontent.com/MPUSP/mpusp-snakemake-wrappers/refs/heads/main/rgi"
