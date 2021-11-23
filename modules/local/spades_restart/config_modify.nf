//
// Modify config.info file to restart spades
//

// Import generic module functions
include { initOptions } from './functions'

params.options = [:]
options        = initOptions(params.options)

process CONFIG_MODIFY {
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
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"

    """
    dirs=(\$(ls -d -r ${saves}/K*))
    kDir=\$(basename \${dirs[0]})
    kDir_previous=\$(basename \${dirs[1]})


    # Modify config.info
    config="${saves}/\${kDir}/configs/config.info"
    basename=\$(basename \${config})
    ext=\${basename##*.}
    filename=\${basename%.*}
    config_old="${saves}/\${kDir}/configs/\${filename}.old.CONFIG_MODIFY.\${ext}"
    cp \${config} \${config_old}
    sed -i "s|output_base.*|output_base ${prefix}.spades_out|" \$config
    sed -i "s|tmp_dir.*|tmp_dir ${prefix}.spades_out/tmp|" \$config
    sed -i "s|dataset.*|dataset ${saves}/dataset.info|" \$config
    sed -i "s|^additional_contigs.*|additional_contigs ${saves}/\${kDir_previous}/simplified_contigs|" \$config
    sed -i "s|load_from.*|load_from ${saves}/\${kDir}/saves|" \$config
    sed -i "s|entry_point read_conversion.*|;entry_point read_conversion|" \$config
    sed -i "s|;entry_point repeat_resolving.*|entry_point repeat_resolving|" \$config
    """
}
