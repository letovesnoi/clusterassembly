// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SPADES_RESTART {
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
    tuple val(sample), path(saves)

    output:
    tuple val(sample), path('*.scaffolds.fa')                    , optional:true, emit: scaffolds
    tuple val(sample), path('*.contigs.fa')                      , optional:true, emit: contigs
    tuple val(sample), path('*.transcripts.fa')                  , optional:true, emit: transcripts
    tuple val(sample), path('*.assembly.gfa')                    , optional:true, emit: gfa
    tuple val(sample), path('*.log')                             , emit: log
    path  '*.version.txt'                                        , emit: version

    script:
    def software    = getSoftwareName(task.process)
    def prefix      = options.suffix ? "${sample}${options.suffix}" : "${sample}"

    """
    kDir="K0"
    for path in \$(ls -d ${saves}/K*); do
        dir=\$(basename \${path})
        if ((\${dir:1} > \${kDir:1})); then
            kDir=\${dir}
        fi
    done

    # Modify config.info
    config="${saves}/\${kDir}/configs/config.info"
    config_restart="${saves}/\${kDir}/configs/config_restart.info"
    cp \$config \$config_restart
    sed -i "s/output_base.*/output_base ${prefix}.spades_out/" \$config_restart
    sed -i "s/tmp_dir.*/tmp_dir ${prefix}.spades_out\\/tmp/" \$config_restart
    sed -i "s/entry_point read_conversion.*/\\;entry_point read_conversion/" \$config_restart
    sed -i "s/\\;entry_point repeat_resolving.*/entry_point repeat_resolving/" \$config_restart

    # Replace binary alignment files with blank files to get only short reads assembly
    for path in \$(ls -d ${saves}/\${kDir}/saves/distance_estimation/graph_pack_*.mpr); do
        basename=\$(basename \${path})
        ext=\${basename##*.}
        filename=\${basename%.*}
        mpr_old="${saves}/\${kDir}/saves/distance_estimation/\${filename}.old.\${ext}"
        mv \${path} \${mpr_old}
        zero_byte="\\x00"
        echo -n -e \${zero_byte} > \${path}
    done

    # Create output directories
    mkdir ${prefix}.spades_out
    mkdir ${prefix}.spades_out/tmp

    # Run spades restart
    spades-core \$config_restart ${saves}/\${kDir}/configs/mda_mode.info ${saves}/\${kDir}/configs/rna_mode.info > ${prefix}.spades.log

    # Move resulting files
    if [ -f ${prefix}.spades_out/\${kDir}/scaffolds.fasta ]; then
        mv ${prefix}.spades_out/\${kDir}/scaffolds.fasta ${prefix}.scaffolds.fa
    fi
    if [ -f ${prefix}.spades_out/\${kDir}/contigs.fasta ]; then
        mv ${prefix}.spades_out/\${kDir}/contigs.fasta ${prefix}.contigs.fa
    fi
    if [ -f ${prefix}.spades_out/\${kDir}/transcripts.fasta ]; then
        mv ${prefix}.spades_out/\${kDir}/transcripts.fasta ${prefix}.transcripts.fa
    fi
    if [ -f ${prefix}.spades_out/\${kDir}/assembly_graph_with_scaffolds.gfa ]; then
        mv ${prefix}.spades_out/\${kDir}/assembly_graph_with_scaffolds.gfa ${prefix}.assembly.gfa
    fi

    # Get spades version
    echo \$(spades.py --version 2>&1) | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//' > ${software}.version.txt
    """
}
