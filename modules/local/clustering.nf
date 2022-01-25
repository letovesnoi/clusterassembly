// Import generic module functions
include { initOptions; saveFiles} from './functions'

params.options = [:]
options        = initOptions(params.options)

process CLUSTERING {
    tag "$sample"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'pipeline_info', meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ?
        "python=3.5.5 biopython==1.72 networkx==2.2 boltons==19.1.0 scipy==1.1 scikit-learn==0.20.0 python-louvain=0.13 umap-learn=0.3.2 seaborn"
        : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(sample), path(saves), path(gfa), path(grseq), path(readable_fmt)

    output:
    tuple val(sample), path('*.clustering.tsv'),    emit: clustering

    script: // This script is bundled with the pipeline, in nf-core/clusterassembly/bin/
    def prefix     = options.suffix ? "${sample}${options.suffix}" : "${sample}"
    def alignments = ( readable_fmt.size() == 1 ) ? " --friendships_reads ${readable_fmt[0]}" : " --friendships_reads ${readable_fmt[0]} --friendships_db ${readable_fmt[1]} --ground_truth ${readable_fmt[1]}"

    """
    conda install pip=20.1.1
    export PYTHONPATH=
    mkdir logs
    pip install numpy==1.18.5 >> logs/install_numpy.log
    pip install absl-py==0.6.1 >> logs/install_absl.log
    pip install gensim==0.13.2 >> logs/install_gensim.log
    pip install pandas==0.25.3 >> logs/install_pandas.log
    pip install matplotlib==2.2.2 >> logs/install_matplotlib.log

    basename=\$(basename ${grseq})
    ext=\${basename##*.}
    filename=\${basename%.*}
    show_saves.py \${filename}.grp > \${filename}.readable.grp

    dirs=(\$(ls -d -r ${saves}/K*))
    kDir=\$(basename \${dirs[0]})
    k_size=\${kDir:1}

    nxG2clusters.py                                 \\
    --gfa ${gfa}                                    \\
    --grp \$(realpath \${filename}.readable.grp)    \\
    ${alignments}                                   \\
    -k \${k_size}                                   \\
    -o ${prefix}.clustering_out

    if [ -f ${prefix}.clustering_out/clustering.tsv ]; then
        mv ${prefix}.clustering_out/clustering.tsv ${prefix}.clustering.tsv
    fi
    """
}
