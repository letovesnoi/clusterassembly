//
// Uncompress and prepare reference genome files
//

include { GUNZIP as GUNZIP_FASTA } from '../../modules/nf-core/modules/gunzip/main'
include { GUNZIP as GUNZIP_GTF   } from '../../modules/nf-core/modules/gunzip/main'

workflow PREPARE_GENOME {

    main:

    ch_versions = Channel.empty()

    if (params.fasta.endsWith('.gz')) {
        ch_fasta    = GUNZIP_FASTA ( [ [:], params.fasta ] ).gunzip.map { it[1] }
        ch_versions = ch_versions.mix(GUNZIP_FASTA.out.versions)
    } else {
        ch_fasta = file(params.fasta)
    }

    //
    // Uncompress GTF annotation file
    //
    if (params.gtf) {
        if (params.gtf.endsWith('.gz')) {
            ch_gtf      = GUNZIP_GTF ( [ [:], params.gtf ] ).gunzip.map { it[1] }
            ch_versions = ch_versions.mix(GUNZIP_GTF.out.versions)
        } else {
            ch_gtf = file(params.gtf)
        }
    }

    emit:
    fasta            = ch_fasta                   //    path: genome.fasta
    gtf              = ch_gtf                     //    path: genome.gtf
    versions         = ch_versions.ifEmpty(null)  // channel: [ versions.yml ]
}
