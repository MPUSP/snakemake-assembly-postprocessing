rule get_fasta:
    input:
        get_fasta,
    output:
        fasta=os.path.join(
            OUTDIR, "annotation/pgap/prepare_files/{sample}/genome.fasta"
        ),
    conda:
        "../envs/base.yml"
    log:
        os.path.join(
            OUTDIR, "annotation/pgap/prepare_files/logs/{sample}_get_fasta.log"
        ),
    shell:
        "INPUT=$(realpath {input}); "
        "ln -s ${{INPUT}} {output}; "
        "echo -e 'created symbolic link to genome fasta: {output}' > {log}"


rule prepare_yaml_files:
    input:
        fasta=rules.get_fasta.output.fasta,
    output:
        input_yaml=os.path.join(
            OUTDIR, "annotation/pgap/prepare_files/{sample}/input.yaml"
        ),
        submol_yaml=os.path.join(
            OUTDIR, "annotation/pgap/prepare_files/{sample}/submol.yaml"
        ),
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
        os.path.join(
            OUTDIR,
            "annotation/pgap/prepare_files/logs/{sample}_prepare_yaml_files.log",
        ),
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
        os.path.join(OUTDIR, "annotation/pgap/{sample}/{sample}.gff"),
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
        os.path.join(OUTDIR, "annotation/pgap/logs/{sample}_pgap.log"),
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
        os.path.join(OUTDIR, "annotation/prokka/{sample}/{sample}.gff"),
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
        os.path.join(OUTDIR, "annotation/prokka/logs/{sample}_prokka.log"),
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
        db=directory(os.path.join(OUTDIR, "annotation/bakta/database/db")),
    conda:
        "../envs/bakta.yml"
    message:
        """--- Getting BAKTA database for annotation ---"""
    params:
        db=config["bakta"]["db"],
    threads: workflow.cores * 0.25
    log:
        os.path.join(OUTDIR, "annotation/bakta/database/db.log"),
    shell:
        """
        echo 'The most recent of the following available bakta DBs is downloaded:' > {log};
        bakta_db list > {log};
        bakta_db download --output {output.db} --type {params.db} &> {log}
        """


rule annotate_bakta:
    input:
        fasta=rules.get_fasta.output.fasta,
        db=rules.get_bakta_db.output.db,
    output:
        os.path.join(OUTDIR, "annotation/bakta/{sample}/{sample}.gff"),
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
        subdir="db" if config["bakta"]["db"] == "full" else "db-light",
        extra=config["bakta"]["extra"],
    threads: workflow.cores * 0.25
    log:
        os.path.join(OUTDIR, "annotation/bakta/logs/{sample}_bakta.log"),
    shell:
        """
        bakta \
          --db {input.db}/{params.subdir} \
          --prefix {params.prefix} \
          --output {params.outdir} \
          --locus-tag {params.locustag} \
          --species '{params.species}' \
          --strain {params.strain} \
          --threads {threads} \
          --force {params.extra} \
          {input.fasta} &> {log};
          mv {output}3 {output}
        """
