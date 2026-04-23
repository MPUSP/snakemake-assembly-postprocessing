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
          echo 'Using supplied CheckM DB from: {params.existing_db}' > {log};
          ln -s {params.existing_db} {output.db};
        else
          echo "The most recent checkM DB will be downloaded..." > {log};
          checkm2 database --download --path {params.outdir} &>> {log};
          ln -s {params.outdir}/CheckM2_database/uniref100.KO.1.dmnd {output.db};
        fi;
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
          &> {log};
          rm -f {params.outdir}/checkm2.log
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


rule rgi_detection:
    input:
        fasta=get_fasta,
    output:
        multiext("results/qc/rgi/{sample}/result", ".txt", ".json"),
    log:
        "results/qc/rgi/{sample}/result.log",
    threads: max(workflow.cores * 0.25, 1)
    params:
        input_type="contig",
        extra=config["rgi"]["extra"],
    message:
        """--- Running RGI to detect antibiotic resistance genes ---"""
    wrapper:
        "https://raw.githubusercontent.com/MPUSP/mpusp-snakemake-wrappers/refs/heads/main/rgi"


rule synteny_detection:
    input:
        fastas=get_fasta_ntsynt,
    output:
        tsv="results/qc/genome_synteny/ntSynt.synteny_blocks.tsv",
        fai=directory("results/qc/genome_synteny/fai"),
    log:
        "results/qc/genome_synteny/logs/ntsynt.log",
    conda:
        "../envs/ntsynt.yml"
    threads: workflow.cores
    params:
        outdir=lambda wc, output: os.path.dirname(output.tsv),
        divergence=config["synteny"]["divergence"],
        extra=config["synteny"]["extra"],
    message:
        """--- Running ntSynt for multi-genome macrosynteny synteny detection ---"""
    shell:
        """
        ntSynt {input.fastas} \
          -d {params.divergence} \
          -t {threads} \
          --force \
          --prefix ntSynt \
          {params.extra} \
          > {log} 2>&1;
        echo "Synteny detection completed. Moving results to output directory." >> {log};
        rsync ./ntSynt.* {params.outdir}/;
        echo "Create fai output directory." >> {log};
        mkdir -p {output.fai};
        rsync ./*.fai {output.fai}/;
        echo "Remove intermediate files." >> {log};
        rm -f ./*.fai ./*.tsv ./*.bf ./*.dot
        """


rule prepare_names:
    output:
        "results/qc/genome_synteny/ntsynt-viz_name_conversion.tsv",
    log:
        "results/qc/genome_synteny/logs/prepare_ntsynt-viz_names.log",
    conda:
        "../envs/base.yml"
    threads: 1
    params:
        sample_sheet=config["samplesheet"],
        ref=(
            (config["reference"]["fasta"], config["reference"]["name"])
            if config["reference"]["fasta"]
            else []
        ),
    message:
        """--- Preparing name mapping file for ntSynt visualization ---"""
    script:
        "../scripts/prepare_names.py"


rule viz_synteny:
    input:
        blocks=rules.synteny_detection.output.tsv,
        fai=rules.synteny_detection.output.fai,
        names=rules.prepare_names.output,
    output:
        pdf="results/qc/genome_synteny/ntSynt-viz_ribbon-plot.pdf",
    log:
        "results/qc/genome_synteny/logs/ntsynt-viz.log",
    conda:
        "../envs/ntsynt.yml"
    threads: 1
    params:
        outdir=lambda wc, output: os.path.dirname(output.pdf),
        fais=lambda wc, input: " ".join(glob.glob(os.path.join(input.fai, "*.fai"))),
        scale=config["synteny"]["viz_scale"],
        ref_fasta=(
            [
                "--target-genome",
                config["reference"]["name"].replace("_", "-").replace(" ", "_"),
            ]
            if config["reference"]["fasta"] and config["reference"]["name"]
            else (
                ["--target-genome", config["reference"]["fasta"]]
                if config["reference"]["fasta"]
                else []
            )
        ),
        extra=config["synteny"]["viz_extra"],
    message:
        """--- Running ntSynt-viz to generate multi-genome ribbon plots ---"""
    shell:
        """
        ntsynt_viz.py \
          --blocks {input.blocks} \
          --fais {params.fais} \
          --name_conversion {input.names} \
          {params.ref_fasta} \
          --scale {params.scale} \
          --format pdf \
          --prefix ntSynt-viz \
          {params.extra} \
          > {log} 2>&1;
          echo "Synteny-viz completed. Moving results to output directory." >> {log};
        rsync ./ntSynt.* {params.outdir}/;
        rsync ./ntSynt-viz.* {params.outdir}/;
        rsync ./ntSynt-viz_* {params.outdir}/;
        echo "Clean intermediate files." >> {log};
        rm -f ./ntSynt-viz.*.tsv ./ntSynt-viz_* ./ntSynt.*.tsv;
        """
