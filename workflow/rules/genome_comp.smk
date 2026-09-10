rule prepare_panaroo:
    input:
        fasta="results/annotation/{tool}/{sample}/{sample}.fna",
        gff="results/annotation/{tool}/{sample}/{sample}.gff",
    output:
        fasta="results/panaroo/{tool}/prepare/{sample}.fna",
        gff="results/panaroo/{tool}/prepare/{sample}.gff",
    log:
        "results/panaroo/{tool}/prepare/{sample}.log",
    conda:
        "../envs/panaroo.yml"
    params:
        remove_source=config["panaroo"]["remove_source"],
        remove_feature=config["panaroo"]["remove_feature"],
    message:
        """--- Prepare input files for pan-genome alignment ---"""
    shell:
        """
        echo 'Preparing annotation for Panaroo:' >{log}
        echo '  - formatting seqnames in FASTA files' >>{log}
        awk '{{ sub(/>.*\\|/, ">"); sub(/[[:space:]].*$/, ""); print }}' \
            {input.fasta} >{output.fasta} 2>>{log}
        echo '  - removing sequences and selected features in GFF files' >>{log}
        awk ' /^##FASTA/ {{exit}} $2 !~ /{params.remove_source}/ && $3 !~ /{params.remove_feature}/ {{print}}' \
            {input.gff} >{output.gff} 2>>{log}
        """


rule panaroo:
    input:
        gff=get_panaroo_gff,
        fasta=get_panaroo_fasta,
    output:
        stats="results/panaroo/{tool}/summary_statistics.txt",
    log:
        "results/panaroo/{tool}/panaroo.log",
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
        printf '%s\n' {input.gff} \
            | paste -d ' ' - <(printf '%s\n' {input.fasta}) \
                >{params.outdir}/input_files.txt
        panaroo \
            -i {params.outdir}/input_files.txt \
            -o {params.outdir} \
            -t {threads} \
            {params.extra} \
            >{log} 2>&1
        """


rule fastani:
    input:
        fasta=get_all_fasta,
    output:
        txt="results/fastani/summary.txt",
    log:
        "results/fastani/fastani.log",
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
        printf '%s\n' {input.fasta} >{params.outdir}/input_files.txt
        printf '%s\n' {params.ref_fasta} >>{params.outdir}/input_files.txt
        fastANI \
            --ql {params.outdir}/input_files.txt \
            --rl {params.outdir}/input_files.txt \
            --output {output.txt} \
            --threads {threads} \
            {params.extra} \
            >{log} 2>&1
        """


rule synteny_detection:
    input:
        fastas=get_fasta_ntsynt,
    output:
        tsv="results/genome_synteny/ntSynt.synteny_blocks.tsv",
        fai=directory("results/genome_synteny/fai"),
    log:
        "results/genome_synteny/logs/ntsynt.log",
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
            >{log} 2>&1
        echo "Synteny detection completed. Moving results to output directory." >>{log}
        mv -f ./ntSynt.* {params.outdir}/
        echo "Create fai output directory." >>{log}
        mkdir -p {output.fai}
        mv -f ./*.fai {output.fai}/
        echo "Remove intermediate files." >>{log}
        rm -f ./*.fai ./*.tsv ./*.bf ./*.dot
        """


rule prepare_names:
    output:
        "results/genome_synteny/ntsynt-viz_name_conversion.tsv",
    log:
        "results/genome_synteny/logs/prepare_ntsynt-viz_names.log",
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
        pdf="results/genome_synteny/ntSynt-viz_ribbon-plot.pdf",
    log:
        "results/genome_synteny/logs/ntsynt-viz.log",
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
            >{log} 2>&1
        echo "Synteny-viz completed. Moving results to output directory." >>{log}
        mv -f ./ntSynt.* {params.outdir}/
        mv -f ./ntSynt-viz.* {params.outdir}/
        mv -f ./ntSynt-viz_* {params.outdir}/
        echo "Clean intermediate files." >>{log}
        rm -f ./ntSynt-viz.*.tsv ./ntSynt-viz_* ./ntSynt.*.tsv
        """


rule minimap2_paf:
    input:
        target=config["reference"]["fasta"],
        query=get_fasta,
    output:
        "results/reference_comparison/{sample}_aln.paf",
    log:
        "results/reference_comparison/logs/{sample}_aln.log",
    threads: max(workflow.cores * 0.25, 1)
    params:
        extra=config["reference_comparison"]["minimap2"]["extra"],
        sorting=config["reference_comparison"]["minimap2"]["sorting"],
        sort_extra=config["reference_comparison"]["minimap2"]["sort_extra"],
    message:
        """--- Running assembly-to-assembly mapping using minimap2 ---"""
    wrapper:
        "v9.7.0/bio/minimap2/aligner"


rule paftools_vcf:
    input:
        target=config["reference"]["fasta"],
        query=rules.minimap2_paf.output,
    output:
        vcf="results/reference_comparison/{sample}_aln.vcf",
        vcf_gz="results/reference_comparison/{sample}_aln.vcf.gz",
        index="results/reference_comparison/{sample}_aln.vcf.gz.tbi",
    log:
        "results/reference_comparison/logs/{sample}_vcf.log",
    conda:
        "../envs/vcfutils.yml"
    threads: max(workflow.cores * 0.25, 1)
    params:
        extra=config["reference_comparison"]["paftools"]["extra"],
    message:
        """--- Running assembly-to-assembly mapping using minimap2 ---"""
    shell:
        """
        sort -k6,6 -k8,8n {input.query} \
            | paftools.js call -f {input.target} - \
                {params.extra} 2>{log} \
            | bcftools reheader \
                --threads {threads} \
                -n {wildcards.sample} \
            | vcf-annotate --fill-type \
                >{output.vcf} 2>>{log}
        bgzip -c {output.vcf} >{output.vcf_gz} 2>>{log}
        tabix {output.vcf_gz}
        """


rule merge_vcfs:
    input:
        vcfs=expand(
            "results/reference_comparison/{sample}_aln.vcf.gz", sample=samples.index
        ),
    output:
        merged_vcf_gz="results/reference_comparison/all_merged_aln.vcf.gz",
        index="results/reference_comparison/all_merged_aln.vcf.gz.tbi",
    log:
        "results/reference_comparison/logs/merge_vcfs.log",
    conda:
        "../envs/vcfutils.yml"
    threads: max(workflow.cores * 0.5, 1)
    params:
        extra=config["reference_comparison"]["bcftools"]["extra"],
        num_input=len(samples.index),
    message:
        """--- Merging individual VCF files into a single multi-sample VCF ---"""
    shell:
        """
        if [ {params.num_input} -eq 1 ]; then
            echo "Only one VCF file present. Copying to merged output." >{log}
            cp {input.vcfs} {output.merged_vcf_gz}
        else
            echo "Merging {params.num_input} VCF files using bcftools..." >{log}
            bcftools merge \
                {input.vcfs} \
                {params.extra} \
                --output {output.merged_vcf_gz} \
                >>{log} 2>&1
        fi
        tabix -p vcf {output.merged_vcf_gz}
        """


rule snpeff_build_db:
    input:
        gff=config["reference"]["gff"],
        fasta=config["reference"]["fasta"],
    output:
        db=directory("results/reference_comparison/annotated_vcf/snpeff/custom_db/ref"),
    log:
        "results/reference_comparison/annotated_vcf/snpeff/logs/build_db.log",
    conda:
        "../envs/vcfutils.yml"
    params:
        genome_name=get_chromosome(),
        extra=config["reference_comparison"]["snpeff"]["build"]["extra"],
    message:
        """--- Build custom SnpEff database ---"""
    shell:
        """
        mkdir -p {output.db}
        config="$(realpath $(whereis snpEff | awk '{{print $2}}')).config"
        today="$(date +%Y-%m-%d)"
        cp {input.fasta} {output.db}/sequences.fa
        cp {input.gff} {output.db}/genes.gff
        cp ${{config}} {output.db}/../snpeff.config
        #echo -e "\n# automatic entry by workflow: snakemake-assembly-postprocessing" >>{output.db}/../snpeff.config
        echo -e "ref.genome : snakemake-assembly-postprocessing reference" >>{output.db}/../snpeff.config
        echo -e "\tref.chromosome: {params.genome_name}\n" >>{output.db}/../snpeff.config
        echo -e "\tref.{params.genome_name}.codonTable: Bacterial_and_Plant_Plastid\n" >>{output.db}/../snpeff.config
        echo -e "\tref.retrieval_date : ${{today}}\n" >>{output.db}/../snpeff.config
        snpEff build {params.extra} -c {output.db}/../snpeff.config -gff3 -dataDir $(realpath {output.db}/../) ref >{log} 2>&1
        """


rule snpeff:
    input:
        calls=rules.paftools_vcf.output.vcf_gz,
        db=rules.snpeff_build_db.output.db,
    output:
        calls="results/reference_comparison/annotated_vcf/{sample}_annotated.vcf",
        stats="results/reference_comparison/annotated_vcf/snpeff/{sample}_snpeff.html",
        csvstats="results/reference_comparison/annotated_vcf/snpeff/{sample}_snpeff.csv",
    log:
        "results/reference_comparison/annotated_vcf/snpeff/logs/{sample}_snpeff.log",
    resources:
        java_opts="-XX:ParallelGCThreads=2",
        mem_mb=4096,
    params:
        extra=f"-c results/reference_comparison/annotated_vcf/snpeff/custom_db/snpeff.config {config["reference_comparison"]["snpeff"]["annotate"]["extra"]}",
    message:
        "annotate variants using snpEff"
    wrapper:
        "v9.15.0/bio/snpeff/annotate"


rule snpeff_vcf_to_tab:
    input:
        vcf=rules.snpeff.output.calls,
        gff=config["reference"]["gff"],
        target=config["reference"]["fasta"],
    output:
        tab="results/reference_comparison/annotated_vcf/{sample}_annotated.tab",
        vcf_gz="results/reference_comparison/annotated_vcf/{sample}_annotated.vcf.gz",
        index="results/reference_comparison/annotated_vcf/{sample}_annotated.vcf.gz.tbi",
    log:
        "results/reference_comparison/annotated_vcf/snpeff/logs/{sample}_snpeff_tab.log",
    conda:
        "../envs/vcfutils.yml"
    threads: 1
    message:
        """--- Converting SnpEff annotated VCF to tabular format ---"""
    shell:
        """
        snippy-vcf_to_tab \
            --ref {input.target} \
            --gff {input.gff} \
            --vcf {input.vcf} \
            >{output.tab} 2>{log}
        bgzip -c {input.vcf} >{output.vcf_gz} 2>>{log}
        tabix -p vcf {output.vcf_gz}
        """


rule dotplot:
    input:
        query=rules.minimap2_paf.output,
    output:
        pdf="results/reference_comparison/{sample}_dotplot.pdf",
        png="results/reference_comparison/{sample}_dotplot.png",
    log:
        path="results/reference_comparison/logs/{sample}_dotplot.log",
    conda:
        "../envs/vcfutils.yml"
    threads: 1
    params:
        query=lambda wc: samples.loc[samples["sample"] == wc.sample, "strain"].values[0],
        target=(
            config["reference"]["name"]
            if config["reference"]["name"]
            else os.path.splitext(os.path.basename(config["reference"]["fasta"]))[0]
        ),
    message:
        """--- Generating dotplot for assembly-to-assembly comparison ---"""
    script:
        "../scripts/create_dotplot.R"
