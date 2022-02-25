// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process CAT_READS {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'merged_reads', meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "conda-forge::sed=4.7" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://containers.biocontainers.pro/s3/SingImgsRepo/biocontainers/v1.2.0_cv1/biocontainers_v1.2.0_cv1.img"
    } else {
        container "biocontainers/biocontainers:v1.2.0_cv1"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.merged.*")    , emit: reads
    path "versions.yml"                    , emit: versions

    script:

    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def readList = reads.collect{ it.toString() }
    if (meta.single_end) {
        if (readList.size > 1) {
            """
            basename=\$(basename ${readList[0]})
            ext=\${basename#*.}

            cat ${readList.sort().join(' ')} > ${prefix}.merged.\${ext}

            cat <<-END_VERSIONS > versions.yml
            ${getProcessName(task.process)}:
                ${getSoftwareName(task.process)}: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
            END_VERSIONS
            """
        }
    } else {
        if (readList.size > 2) {
            def read1 = []
            def read2 = []
            readList.eachWithIndex{ v, ix -> ( ix & 1 ? read2 : read1 ) << v }
            """
            basename=\$(basename ${readList[0]})
            ext=\${basename#*.}

            cat ${read1.sort().join(' ')} > ${prefix}_1.merged.\${ext}
            cat ${read2.sort().join(' ')} > ${prefix}_2.merged.\${ext}

            cat <<-END_VERSIONS > versions.yml
            ${getProcessName(task.process)}:
                ${getSoftwareName(task.process)}: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
            END_VERSIONS
            """
        }
    }
}
