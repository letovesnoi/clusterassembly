//
// Get readable alignment file from spades binary mpr
//

// Import generic module functions
include { getSoftwareName } from './functions'

params.options = [:]

process MPR_TO_READABLE {
    tag "${sample}"
    conda (params.enable_conda ? "conda-forge::python=3.8.3 conda-forge::biopython" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(mprs)

    output:
    tuple val(sample), path('*.readable_mpr'), emit: readable_mprs

    script:

    """
    # Get readable alignment files from binary mprs
    for path in $mprs; do
        basename=\$(basename \${path})
        ext=\${basename##*.}
        filename=\${basename%.*}
        readable_path="\${filename}.readable_mpr"
        show_saves.py \${path} > \${readable_path}
    done
    """
}
