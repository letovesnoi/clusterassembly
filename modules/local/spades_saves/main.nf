// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SPADES_SAVES {
    tag "$sample"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:['id': sample], publish_by_meta:['id']) }

    conda (params.enable_conda ? 'bioconda::spades=3.15.3 python=3.9' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/spades:3.15.3--h95f258a_0"
    } else {
        container "quay.io/biocontainers/spades:3.15.3--h95f258a_0"
    }

    input:
    tuple val(sample), path(short_reads), path(long_reads), path(db_seq)

    output:
    tuple val(sample), path('*.spades_out')           , emit: saves
    tuple val(sample), path('*.scaffolds.fa')         , optional:true, emit: scaffolds
    tuple val(sample), path('*.contigs.fa')           , optional:true, emit: contigs
    tuple val(sample), path('*.transcripts.fa')       , emit: transcripts
    tuple val(sample), path('*.assembly.gfa')         , emit: gfa
    tuple val(sample), path('*.grseq')                , emit: grseq
    tuple val(sample), path('*.mpr')                  , emit: mprs
    tuple val(sample), path('*.spades.log')           , emit: log
    path  '*.version.txt'                             , emit: version

    script:
    def software    = getSoftwareName(task.process)
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"
    def input_reads = ( short_reads.size() == 1 ) ? "-s ${short_reads[0]}" : "-1 ${short_reads[0]} -2 ${short_reads[1]}"
    input_reads     += long_reads ? " --pacbio ${long_reads[0]}" : ""
    input_reads     += db_seq ? " --pacbio ${db_seq[0]}" : ""

    """
    spades.py \\
        $options.args \\
        --threads $task.cpus \\
        ${input_reads} \\
        -o ${prefix}.spades_out
    mv ${prefix}.spades_out/spades.log ${prefix}.spades.log
    if [ -f ${prefix}.spades_out/scaffolds.fasta ]; then
        mv ${prefix}.spades_out/scaffolds.fasta ${prefix}.scaffolds.fa
    fi
    if [ -f ${prefix}.spades_out/contigs.fasta ]; then
        mv ${prefix}.spades_out/contigs.fasta ${prefix}.contigs.fa
    fi
    if [ -f ${prefix}.spades_out/transcripts.fasta ]; then
        mv ${prefix}.spades_out/transcripts.fasta ${prefix}.transcripts.fa
    fi
    if [ -f ${prefix}.spades_out/assembly_graph_with_scaffolds.gfa ]; then
        mv ${prefix}.spades_out/assembly_graph_with_scaffolds.gfa ${prefix}.assembly.gfa
    fi

    dirs=(\$(ls -d -r ${prefix}.spades_out/K*))
    kDir=\$(basename \${dirs[0]})
    if [ -f ${prefix}.spades_out/\${kDir}/saves/distance_estimation/graph_pack.grseq ]; then
        cp ${prefix}.spades_out/\${kDir}/saves/distance_estimation/graph_pack.grseq ${prefix}.grseq
    fi
    if [ -f  ${prefix}.spades_out/\${kDir}/saves/distance_estimation/graph_pack_0.mpr ]; then
        cp ${prefix}.spades_out/\${kDir}/saves/distance_estimation/graph_pack_0.mpr graph_pack_0.mpr
    fi
    if [ -f  ${prefix}.spades_out/\${kDir}/saves/distance_estimation/graph_pack_1.mpr ]; then
        cp ${prefix}.spades_out/\${kDir}/saves/distance_estimation/graph_pack_1.mpr graph_pack_1.mpr.mpr
    fi

    echo \$(spades.py --version 2>&1) | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//' > ${software}.version.txt
    """
}
