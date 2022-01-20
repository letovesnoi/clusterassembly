//
// Replace *.mpr alignment files with blank to get only short reads assembly using spades restart
//

// Import generic module functions
include { getSoftwareName } from './functions'

params.options = [:]

process MPR_TO_READABLE {
    tag "${saves}"
    conda (params.enable_conda ? "conda-forge::python=3.8.3 conda-forge::biopython" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(saves)

    output:
    tuple val(sample), path('*.readable_fmt'), emit: alignments

    script:

    """
    dirs=(\$(ls -d -r ${saves}/K*))
    kDir=\$(basename \${dirs[0]})

    # Get readable alignment files from binary mpr
    for path in \$(ls -d ${saves}/\${kDir}/saves/distance_estimation/graph_pack_*.mpr); do
        basename=\$(basename \${path})
        ext=\${basename##*.}
        filename=\${basename%.*}
        readable_path="\${filename}.readable_fmt"
        show_saves.py \${path} > \${readable_path}
    done
    """
}
