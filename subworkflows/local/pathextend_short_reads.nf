//
// Restart spades from the last checkpoint (the same as run pathextend) using only short reads
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

include { CONFIG_MODIFY } from '../../modules/local/spades_restart/config_modify' addParams ( options: modules['restart_short_reads'])
include { MPR_NULLIFY } from '../../modules/local/spades_restart/mpr_nullify' addParams ( options: modules['restart_short_reads'])
include{ COPY_DIR } from '../../modules/local/spades_restart/copy_dir' addParams ( options: modules['restart_short_reads'])
include { SPADES_RESTART } from '../../modules/local/spades_restart/main' addParams( options: modules['restart_short_reads'] )

workflow PATHEXTEND_SHORT_READS {
    take:
    saves // [ tuple val(sample), path(/path/to/spades_output) ]

    main:
        COPY_DIR ( saves )
        CONFIG_MODIFY ( COPY_DIR.out )
        MPR_NULLIFY ( CONFIG_MODIFY.out )
        SPADES_RESTART ( MPR_NULLIFY.out )

    emit:
    transcripts = SPADES_RESTART.out.transcripts // channel: [ path to transcripts ]
}
