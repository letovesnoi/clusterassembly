//
// Evaluate transcripts against protein databases
//

// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)


process AGAINST_PROTEINS_EVALUATION {
    tag "${sample}"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'metrics_out', meta:[:], publish_by_meta:[]) }
    conda (params.enable_conda ? "conda-forge::python=3.8.3 biopython bioconda::diamond bioconda::interproscan bioconda::mmseqs2 bioconda::prodigal bioconda::pyfasta" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(short_reads_transcripts), path(all_transcripts), path(clusters_transcripts)

    output:
    tuple val(sample), path('${prefix}.proteins_metrics/*.results.txt'), emit: short_report

    script:
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"

    """
    QA_against_proteins.py ${short_reads_transcripts} ${prefix}.proteins_metrics
    QA_against_proteins.py ${all_transcripts} ${prefix}.proteins_metrics
    QA_against_proteins.py ${clusters_transcripts} ${prefix}.proteins_metrics
    """
}
