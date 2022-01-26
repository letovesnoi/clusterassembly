//
// Quality evaluation and assessment of transcriptome assemblies (including clustering metrics)
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

include { CLUSTERING_EVALUATION } from '../../modules/local/evaluation/clustering_evaluation' addParams( options: modules['clustering_evaluation'] )
// include { AGAINST_PROTEINS_EVALUATION } from '../../modules/local/evaluation/against_proteins_evaluation' addParams( options: modules['against_proteins_evaluation'] )
// include { RNAQUAST_EVALUATION } from '../../modules/local/evaluation/rnaquast_evaluation' addParams( options: modules['rnaquast_evaluation'] )

workflow QUALITY_ASSESSMENT {
    take:
    clustering
    readable_mprs

    main:
        CLUSTERING_EVALUATION ( clustering.join(readable_mprs) )
//         AGAINST_PROTEINS_EVALUATION ( TODO )
//         RNAQUAST_EVALUATION ( TODO )

    emit:
    clustering_report = CLUSTERING_EVALUATION.out.short_report   // channel: [ path to short report ]
//     against_proteins_report = AGAINST_PROTEINS_EVALUATION.out.report // channel: [ path to short report ]
//     rnaquast_report = RNAQUAST_EVALUATION.out.report // channel: [ path to short report ]
}
