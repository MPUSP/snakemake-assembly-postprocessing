rule get_fasta:
    input:
        get_fasta,
    output:
        fasta="results/annotation/pgap/prepare_files/{sample}/genome.fasta",
    conda:
        "../envs/base.yml"
    log:
        "results/annotation/pgap/prepare_files/logs/{sample}_get_fasta.log",
    shell:
        "INPUT=$(realpath {input}); "
        "ln -s ${{INPUT}} {output}; "
        "echo -e 'created symbolic link to genome fasta: {output}' > {log}"


rule prepare_yaml_files:
    input:
        fasta=rules.get_fasta.output.fasta,
    output:
        input_yaml="results/annotation/pgap/prepare_files/{sample}/input.yaml",
        submol_yaml="results/annotation/pgap/prepare_files/{sample}/submol.yaml",
    conda:
        "../envs/base.yml"
    params:
        locus_tag=lambda wc: samples.loc[wc.sample]["id_prefix"],
        organism=lambda wc: samples.loc[wc.sample]["species"],
        generic=config["pgap"]["prepare_yaml_files"]["generic"],
        submol=config["pgap"]["prepare_yaml_files"]["submol"],
        sample="{sample}",
        pd_samples=samples,
    log:
        "results/annotation/pgap/prepare_files/logs/{sample}_prepare_yaml_files.log",
    script:
        "../scripts/prepare_yaml_files.py"


rule annotate_pgap:
    input:
        branch(
            lookup(dpath="pgap/use_yaml_config", within=config),
            then=rules.prepare_yaml_files.output.input_yaml,
            otherwise=rules.get_fasta.output.fasta,
        ),
    output:
        gff="results/annotation/pgap/{sample}/{sample}.gff",
        fasta="results/annotation/pgap/{sample}/{sample}.fna",
    conda:
        "../envs/base.yml"
    message:
        """--- Running PGAP annotation for sample {wildcards.sample} ---"""
    params:
        pgap=config["pgap"]["bin"],
        use_yaml_config=config["pgap"]["use_yaml_config"],
        species=lambda wc: samples.loc[wc.sample]["species"],
        outdir=lambda wc, output: os.path.dirname(output[0]),
    threads: 1
    log:
        "results/annotation/pgap/logs/{sample}_pgap.log",
    shell:
        "rm -rf {params.outdir}; "
        "if [ {params.use_yaml_config} == 'True' ]; then "
        "echo -e 'Using YAML configuration for PGAP annotation' > {log}; "
        "{params.pgap} -n "
        "-o {params.outdir} "
        "--docker apptainer "
        "--prefix {wildcards.sample} "
        "--no-self-update "
        "{input} &>> {log}; "
        "else "
        "echo -e 'Using FASTA file and species name for PGAP annotation' > {log}; "
        "{params.pgap} -n "
        "-o {params.outdir} "
        "--docker apptainer "
        "--prefix {wildcards.sample} "
        "--no-self-update "
        "-g {input} -s '{params.species}' &>> {log}; "
        "fi; "


rule annotate_prokka:
    input:
        fasta=rules.get_fasta.output.fasta,
    output:
        gff="results/annotation/prokka/{sample}/{sample}.gff",
        fasta="results/annotation/prokka/{sample}/{sample}.fna",
    conda:
        "../envs/prokka.yml"
    message:
        """--- Running PROKKA annotation for sample {wildcards.sample} ---"""
    params:
        prefix=lambda wc: wc.sample,
        locustag=lambda wc: samples.loc[wc.sample]["id_prefix"],
        genus=lambda wc: samples.loc[wc.sample]["species"].split(" ")[0],
        species=lambda wc: samples.loc[wc.sample]["species"].split(" ")[1],
        strain=lambda wc: samples.loc[wc.sample]["strain"],
        outdir=lambda wc, output: os.path.dirname(output[0]),
        extra=config["prokka"]["extra"],
    threads: workflow.cores * 0.25
    log:
        "results/annotation/prokka/logs/{sample}_prokka.log",
    shell:
        """
        prokka \
          --locustag {params.locustag} \
          --genus {params.genus} \
          --species {params.species} \
          --strain {params.strain} \
          --prefix {params.prefix} \
          --outdir {params.outdir} \
          --force {params.extra} \
          --cpus {threads} \
          {input.fasta} &> {log}
        """


rule get_bakta_db:
    output:
        db=branch(
            lookup(dpath="bakta/download_db", within=config),
            cases={
                "full": directory("results/annotation/bakta/database/db"),
                "light": directory("results/annotation/bakta/database/db-light"),
                "none": directory("results/annotation/bakta/database/custom"),
            },
        ),
    conda:
        "../envs/bakta.yml"
    message:
        """--- Getting BAKTA database for annotation ---"""
    params:
        download_db=config["bakta"]["download_db"],
        existing_db=config["bakta"]["existing_db"],
        outdir=lambda wc, output: os.path.dirname(output[0]),
    threads: workflow.cores * 0.25
    log:
        "results/annotation/bakta/database/db.log",
    shell:
        """
        if [ {params.download_db} != 'none' ]; then
          echo 'The most recent of the following available Bakta DBs is downloaded:' > {log};
          bakta_db list &>> {log};
          bakta_db download --output {params.outdir} --type {params.download_db} &>> {log};
        else
          echo 'Using Bakta DB from supplied input dir: {params.existing_db}' > {log};
          ln -s {params.existing_db} {output.db};
          echo 'Update ARMFinderPlus DB using supplied input dir: {params.existing_db}' >> {log};
          amrfinder_update --force_update --database {params.existing_db}/amrfinderplus-db &>> {log}
        fi
        """


rule annotate_bakta:
    input:
        fasta=rules.get_fasta.output.fasta,
        db=rules.get_bakta_db.output.db,
    output:
        gff="results/annotation/bakta/{sample}/{sample}.gff",
        fasta="results/annotation/bakta/{sample}/{sample}.fna",
    conda:
        "../envs/bakta.yml"
    message:
        """--- Running BAKTA annotation for sample {wildcards.sample} ---"""
    params:
        prefix=lambda wc: wc.sample,
        locustag=lambda wc: samples.loc[wc.sample]["id_prefix"],
        species=lambda wc: samples.loc[wc.sample]["species"],
        strain=lambda wc: samples.loc[wc.sample]["strain"],
        outdir=lambda wc, output: os.path.dirname(output[0]),
        extra=config["bakta"]["extra"],
    threads: workflow.cores * 0.25
    log:
        "results/annotation/bakta/logs/{sample}_bakta.log",
    shell:
        """
        bakta \
          --db {input.db} \
          --prefix {params.prefix} \
          --output {params.outdir} \
          --locus-tag {params.locustag} \
          --species '{params.species}' \
          --strain {params.strain} \
          --threads {threads} \
          --force {params.extra} \
          {input.fasta} &> {log};
          mv {output.gff}3 {output.gff}
        """
