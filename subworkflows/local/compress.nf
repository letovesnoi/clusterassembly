//
// Gzip reads
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.

params.options = [:]

include { GZIP_READS } from '../../modules/local/gzip_reads' addParams( options: params.options )

workflow COMPRESS {
    take:
    reads // channel: list of [ meta, [ reads_1, reads_2 ] ] or [ meta, [reads_1] ]

    main:
    reads
    .branch { meta, list ->
              compressed: list.first().toString().endsWith('.gz')
              uncompressed: true
    }
    .set { ch_seq }

    GZIP_READS (
        ch_seq.uncompressed
    )
    .gzip
    .mix(ch_seq.compressed)
    .set { ch_compressed }

    emit:
    reads      = ch_compressed
    versions   = GZIP_READS.out.versions.ifEmpty(null)  // channel: [ versions.yml ]
}
