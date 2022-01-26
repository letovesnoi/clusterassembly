//
// Get Jaccard similarity, recall and F1 score for reconstructed clusters against gene database
//

// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)


process CLUSTERING_EVALUATION {
    tag "${sample}"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'metrics_out', meta:[:], publish_by_meta:[]) }
    conda (params.enable_conda ? "python biopython matplotlib networkx scipy pandas" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(reconstructed_clusters), path(readable_mprs)

    output:
    tuple val(sample), path('*.clustering_metrics.txt'), emit: short_report

    when:
    readable_mprs.size() > 1

    script:
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"

    """
    evaluate_clustering.py          \\
    ${reconstructed_clusters}       \\
    ${readable_mprs[1]}             \\
    ${prefix}.clustering_metrics

    if [ -f ${prefix}.clustering_metrics/short_report.txt ]; then
        mv ${prefix}.clustering_metrics/short_report.txt ${prefix}.clustering_metrics.txt
    fi
    """
}
