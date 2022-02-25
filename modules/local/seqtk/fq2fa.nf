//
// Reformat long reads from fastq to fasta
//

// Import generic module functions
include { getSoftwareName } from './functions'

params.options = [:]

process FQ2FA {
    tag "${sample.id}, ${sample.type}"
    conda (params.enable_conda ? "bioconda::seqtk" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(reads)

    output:
    tuple val(sample), path('*.fasta'), emit: reads_in_fasta

    when:
    reads.endsWith('.fastq') or reads.endsWith('.fq') or reads.endsWith('.fastq.gz') or reads.endsWith('.fq.gz')

    script:
    """
    basename=\$(basename ${reads})
    ext=\${basename##*.}
    filename=\${basename%.*}
    seqtk seq -a ${reads} > \${filename}.fasta
    """
}
