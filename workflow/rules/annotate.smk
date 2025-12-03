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
        """--- Run PGAP annotation for sample {wildcards.sample} ---"""
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
