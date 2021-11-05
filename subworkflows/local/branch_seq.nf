//
// Split input channels into paired reads, long reads and db seq channels
//

params.options = [:]

workflow BRANCH_SEQ {
    take:
    ch_seq // channel with all types of sequences together: list of [ meta, [ fastq_1, fastq_2 ] ]

    main:
    ch_seq
        .branch { meta, list ->
                  paired_reads: meta.type == "paired_reads"
                  long_reads: meta.type == "long_reads"
                  db_seq: meta.type == "db_seq"
                  }
        .set { result }

//     result.reads.view { "$it is paired reads" }
//     result.long_reads.view { "$it is long reads" }
//     result.db_seq.view { "$it is database sequences" }

    emit:
        paired_reads = result.paired_reads
        long_reads = result.long_reads
        db_seq = result.db_seq
}
