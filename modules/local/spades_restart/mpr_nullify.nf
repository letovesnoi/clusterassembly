//
// Replace *.mpr alignment files with blank to get only short reads assembly using spades restart
//

// Import generic module functions
include { getSoftwareName } from './functions'

params.options = [:]

process MPR_NULLIFY {
    tag "${saves}"
    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(saves)

    output:
    tuple val(sample), path(saves)

    script:

    """
    dirs=(\$(ls -d -r ${saves}/K*))
    kDir=\$(basename \${dirs[0]})

    # Replace binary alignment files with blank files to get only short reads assembly
    for path in \$(ls -d ${saves}/\${kDir}/saves/distance_estimation/graph_pack_*.mpr); do
        basename=\$(basename \${path})
        ext=\${basename##*.}
        filename=\${basename%.*}
        mpr_old="${saves}/\${kDir}/saves/distance_estimation/\${filename}.old.MPR_NULLIFY.\${ext}"
        mv \${path} \${mpr_old}
        zero_byte="\\x00"
        echo -n -e \${zero_byte} > \${path}
    done
    """
}
