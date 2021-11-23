//
// Restart spades from the last checkpoint (the same as run pathextend) using results of clustering
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

include { CONFIG_MODIFY } from '../../modules/local/spades_restart/config_modify' addParams ( options: modules['restart_clusters'])
include { PE_PARAMS_MODIFY } from '../../modules/local/spades_restart/pe_params_modify' addParams ( options: modules['restart_clusters'])
include{ COPY_DIR } from '../../modules/local/spades_restart/copy_dir' addParams ( options: modules['restart_clusters'])
include { SPADES_RESTART } from '../../modules/local/spades_restart/main' addParams( options: modules['restart_clusters'] )

workflow PATHEXTEND_CLUSTERS {
    take:
    saves     // [ tuple val(sample), path(/path/to/spades_output) ]
    clusters   // [ tuple val(sample), path(/path/to/clusters_csv)]

    main:
        COPY_DIR ( saves )
        CONFIG_MODIFY ( COPY_DIR.out )
        PE_PARAMS_MODIFY ( CONFIG_MODIFY.out, clusters )
        SPADES_RESTART ( PE_PARAMS_MODIFY.out )

    emit:
    SPADES_RESTART.out.transcripts // channel: [ path to transcripts ]
}
