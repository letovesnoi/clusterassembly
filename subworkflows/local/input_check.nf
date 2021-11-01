//
// Check input samplesheet and get read channels
//

params.options = [:]

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check' addParams( options: params.options )

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .splitCsv ( header: true, sep: ',' )
        .map { create_fastq_channels(it) }
        .branch { meta, list ->
                  reads: meta.type == "paired_reads"
                  long_reads: meta.type == "long_reads"
                  db_seq: meta.type == "db_seq"
                  }
        .set { result }

    result.reads.view { "$it is paired reads" }
    result.long_reads.view { "$it is long reads" }
    result.db_seq.view { "$it is database sequences" }

    emit:
        reads = result.reads
        long_reads = result.long_reads
        db_seq = result.db_seq
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.type   = row.type

    def array = []
    if (!file(row.reads_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.reads_1}"
    }
    if (meta.type != "paired_reads") {
        array = [ meta, [ file(row.reads_1) ] ]
    } else {
        if (!file(row.reads_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.reads_2}"
        }
        array = [ meta, [ file(row.reads_1), file(row.reads_2) ] ]
    }
    return array
}

