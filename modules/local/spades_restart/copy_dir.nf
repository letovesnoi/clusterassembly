//
// Copy directory to restart spades
//

// Import generic module functions
include { initOptions } from './functions'

params.options = [:]
options        = initOptions(params.options)

process COPY_DIR {
    tag "${in_saves}"
    stageInMode = 'copy'
    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(in_saves)

    output:
    tuple val(sample), path('*.spades_out.old')

    script:
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"

    """
    mv ${in_saves} ${prefix}.spades_out.old
    """
}
