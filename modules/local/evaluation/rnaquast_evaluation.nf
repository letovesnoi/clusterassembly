// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)


process RNAQUAST_EVALUATION {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'metrics_out', meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? 'bioconda::rnaquast' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    //  [ sample, short_reads_transcripts.fa, all_seq_transcripts.fa, clusters_transcripts.fa ]
    tuple val(sample), path(short_reads_transcripts), path(all_transcripts), path(clusters_transcripts)
    path fasta
    path gtf

    output:
    tuple val(sample), path('*.rnaquast_metrics.txt'), emit: short_report

    script:
    def software    = getSoftwareName(task.process)
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"
    def all_transcripts = "${short_reads_transcripts} ${all_transcripts} ${clusters_transcripts}"

    """
    # Using rnaQUAST against isoform database
    rnaQUAST.py                           \\
    --transcripts ${all_transcripts}      \\
    --reference ${fasta}               \\
    --gtf ${gtf}                       \\
    --output_dir ${prefix}.rnaquast_out   \\
    --disable_infer_genes                 \\
    --disable_infer_transcripts           \\
    --busco auto-lineage

    if [ -f ${prefix}.rnaquast_out/short_report.txt ]; then
        mv ${prefix}.rnaquast_out/short_report.txt ${prefix}.rnaquast_metrics.txt
    fi
    """
}
