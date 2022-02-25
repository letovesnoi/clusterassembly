//
// Reformat reads from fastq to fasta if required
//

// Don't overwrite global params.modules, create a copy instead and use that within the main script.

params.options = [:]

include { FQ2FA } from '../../modules/local/seqtk/fq2fa' addParams( options: params.options )

workflow GET_FASTA {
    take:
    reads // channel: list of [ meta, [ reads_1, reads_2 ] ] or [ meta, [reads_1] ]

    main:
    reads
    .branch {
        meta, list ->
            fq : list.first().toString().endsWith('.fastq.gz') or list.first().toString().endsWith('.fq.gz') or list.first().toString().endsWith('.fastq') or list.first().toString().endsWith('.fq')
            fasta:  list.first().toString().endsWith('.fasta.gz') or list.first().toString().endsWith('.fa.gz') or list.first().toString().endsWith('.fasta') or list.first().toString().endsWith('.fa')
    }
    .set { ch_seq }

    FQ2FA (
        ch_seq.fq
    )
    .reads_in_fasta
    .mix(ch_seq.fasta)
    .set { ch_fasta }

    emit:
    reads = ch_fasta
}
