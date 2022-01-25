//
// Modify pe_params.info file to restart spades with clusters
//

// Import generic module functions
include { getSoftwareName } from './functions'

params.options = [:]

process PE_PARAMS_MODIFY {
    tag "${saves}"
    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(saves), path(clusters)

    output:
    tuple val(sample), path(saves)

    script:

    """
    dirs=(\$(ls -d -r ${saves}/K*))
    kDir=\$(basename \${dirs[0]})

    # Modify pe_params.info
    pe_params="${saves}/\${kDir}/configs/pe_params.info"
    basename=\$(basename \${pe_params})
    ext=\${basename##*.}
    filename=\${basename%.*}
    pe_params_old="${saves}/\${kDir}/configs/\${filename}.old.PE_PARAMS_MODIFY.\${ext}"
    cp \${pe_params} \${pe_params_old}
    sed -i "s|rna_clusters.*|rna_clusters \$(realpath ${clusters})|" \$pe_params
    """
}
