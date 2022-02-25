//
// Concatenate sequence files from the same sample if required (separately for each type of data)
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

def cat_options = modules['cat']
if ( !params.save_merged_fastq ) { cat_options['publish_files'] = false }

include { CAT_READS } from '../../modules/local/cat_reads/main' addParams( options: cat_options )

workflow CONCATENATE {
    take:
    reads // channel: list of [ meta, [ reads_1, reads_2 ] ] or [ meta, [reads_1] ]

    main:
    reads
    .groupTuple(by: [0])
    .branch {
        meta, list ->
            single : list.size() == 1
                return [ meta, list.flatten() ]
            multiple: list.size() > 1
                return [ meta, list.flatten() ]
    }
    .set { ch_seq }

    CAT_READS (
        ch_seq.multiple
    )
    .reads
    .mix(ch_seq.single)
    .set { ch_cat_seq }

    emit:
    reads      = ch_cat_seq
    versions   = CAT_READS.out.versions.ifEmpty(null)  // channel: [ versions.yml ]
}
