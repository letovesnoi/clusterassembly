//
// Quality evaluation and assessment of transcriptome assemblies (including clustering metrics)
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

include { CLUSTERING_EVALUATION } from '../../modules/local/evaluation/clustering_evaluation' addParams( options: modules['clustering_evaluation'] )
include { AGAINST_PROTEINS_EVALUATION } from '../../modules/local/evaluation/against_proteins_evaluation' addParams( options: modules['against_proteins_evaluation'] )
include { RNAQUAST_EVALUATION } from '../../modules/local/evaluation/rnaquast_evaluation' addParams( options: modules['rnaquast_evaluation'] )

workflow QUALITY_ASSESSMENT {
    take:
    clustering
    readable_mprs
    short_reads_transcripts
    all_transcripts
    clusters_transcripts

    main:
        CLUSTERING_EVALUATION ( clustering.join(readable_mprs) )
        AGAINST_PROTEINS_EVALUATION ( short_reads_transcripts.join(all_transcripts).join(clusters_transcripts) )
        RNAQUAST_EVALUATION (
            short_reads_transcripts.join(all_transcripts).join(clusters_transcripts)
          )

    emit:
    clustering_report = CLUSTERING_EVALUATION.out.short_report   // channel: [ path to short report ]
    against_proteins_report = AGAINST_PROTEINS_EVALUATION.out.short_report // channel: [ [ path to short report 1, path to short report 2, path to short report 3] ]
    rnaquast_report = RNAQUAST_EVALUATION.out.short_report // channel: [ path to short report ]
}
