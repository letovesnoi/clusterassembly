/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowClusterassembly.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [
    params.input,
    params.mgy,
    params.fasta, params.gtf
    ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

//
// MODULE: Local to the pipeline
//
include { GET_SOFTWARE_VERSIONS } from '../modules/local/get_software_versions' addParams( options: [publish_files : ['tsv':'']] )
include { SPADES_SAVES } from '../modules/local/spades_saves/main' addParams ( options: modules['spades_saves'], enable_conda: false)
include { MPR_TO_READABLE } from '../modules/local/mpr_to_readable' addParams ( options: [:] )
include { CLUSTERING } from '../modules/local/clustering' addParams ( options: modules['clustering'] )

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check' addParams( options: [:] )
include { BRANCH_SEQ } from '../subworkflows/local/branch_seq' addParams ( options: [:] )
include { PATHEXTEND_SHORT_READS } from '../subworkflows/local/pathextend_short_reads' addParams( options: [:] )
include { PATHEXTEND_CLUSTERS } from '../subworkflows/local/pathextend_clusters' addParams( options: [:] )
include { PREPARE_GENOME } from '../subworkflows/local/prepare_genome' addParams( options: [:])
include { QUALITY_ASSESSMENT } from '../subworkflows/local/quality_assessment' addParams ( options: [:] )
include { COMPRESS as COMPRESS_SHORT_READS } from '../subworkflows/local/compress' addParams ( options: [:] )
include { COMPRESS as COMPRESS_LONG_READS } from '../subworkflows/local/compress' addParams ( options: [:] )
include { GET_FASTA } from '../subworkflows/local/get_fasta' addParams ( options: [:] )
include { CONCATENATE as CONCATENATE_SHORT_READS } from '../subworkflows/local/concatenate' addParams( options: [:] )
include { CONCATENATE as CONCATENATE_LONG_READS } from '../subworkflows/local/concatenate' addParams( options: [:] )

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/
def multiqc_options   = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC  } from '../modules/nf-core/modules/fastqc/main'  addParams( options: modules['fastqc'] )
include { MULTIQC } from '../modules/nf-core/modules/multiqc/main' addParams( options: multiqc_options )

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow CLUSTERASSEMBLY {

    ch_software_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    ).map {
        meta, list ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, list ] }
    .set { ch_seq }

    //
    // SUBWORKFLOW: Split input sequences into short reads, long reads and database sequences
    //
    BRANCH_SEQ (
        ch_seq
    )

    //SHORT READS
    // Compress uncompressed reads files
    COMPRESS_SHORT_READS(
        BRANCH_SEQ.out.short_reads
    )
    // Concatenate short reads files from the same sample if required
    CONCATENATE_SHORT_READS(
        COMPRESS_SHORT_READS.out.reads
    )
    ch_software_versions = ch_software_versions.mix(CONCATENATE_SHORT_READS.out.versions.first().ifEmpty(null))

    // LONG READS
    // Convert long reads to fasta format
    GET_FASTA(
        BRANCH_SEQ.out.long_reads
    )
    // Compress uncompressed reads files
    COMPRESS_LONG_READS(
        GET_FASTA.out.reads
    )
    // Concatenate long reads files from the same sample if required
    CONCATENATE_LONG_READS(
        COMPRESS_LONG_READS.out.reads
    )
    ch_software_versions = ch_software_versions.mix(CONCATENATE_LONG_READS.out.versions.ifEmpty(null))

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        COMPRESS_SHORT_READS.out.reads
    )
    ch_software_versions = ch_software_versions.mix(FASTQC.out.version.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Join short reads, long reads and db sequences channels by sample id
    //
//     [ meta_id, [ fastq_1, fastq_2 ], fasta, fasta ]
    ch_short_reads = CONCATENATE_SHORT_READS.out.reads
    .map { meta, list ->
        sample = meta.id
        [sample, list] }
    ch_long_reads = CONCATENATE_LONG_READS.out.reads
    .map { meta, long_reads ->
        sample = meta.id
        [sample, long_reads] }
    ch_db_seq = BRANCH_SEQ.out.db_seq
    .map { meta, db_seq ->
        sample = meta.id
        [sample, db_seq] }
    all_by_sample = ch_short_reads.join(ch_long_reads, remainder: true).join(ch_db_seq, remainder: true)
    .map { sample, short_reads, long_reads, db_seq ->
        long_reads = Objects.isNull(long_reads) ? ['/'] : long_reads
        db_seq     = Objects.isNull(db_seq) ? ['/'] : db_seq
        [sample, short_reads, long_reads, db_seq] }

    //
    // MODULE: Run SPAdes with short reads and long sequences (long reads and database transcripts)
    //
    SPADES_SAVES (
        all_by_sample
    )
    ch_software_versions = ch_software_versions.mix(SPADES_SAVES.out.version.first().ifEmpty(null))

    //
    // MODULE: Restart SPAdes using only short reads from the last checkpoint using saves
    //
    PATHEXTEND_SHORT_READS (
        SPADES_SAVES.out.saves
    )

    //
    // MODULE: Reformat SPAdes output alignment files from binary mpr to readable format
    //
    MPR_TO_READABLE (
        SPADES_SAVES.out.mprs
    )

    // Get clusters from assembly graph and readable alignment files
    // TODO: use k size instead of saves directory
    clustering_input_channel = SPADES_SAVES.out.saves.join(SPADES_SAVES.out.gfa).join(SPADES_SAVES.out.grseq).join(MPR_TO_READABLE.out.readable_mprs)
    CLUSTERING (
        clustering_input_channel
    )

    //
    // MODULE: Restart SPAdes using clusters from the last checkpoint using saves
    //
    PATHEXTEND_CLUSTERS (
        SPADES_SAVES.out.saves,
        CLUSTERING.out.clustering
    )

    //
    // SUBWORKFLOW: Uncompress and download reference genome files (fasta and gtf)
    //
    PREPARE_GENOME ()

    //
    // MODULE: Quality evaluation and assessment of transcriptome assemblies
    //
    QUALITY_ASSESSMENT (
        CLUSTERING.out.clustering,
        MPR_TO_READABLE.out.readable_mprs,
        PATHEXTEND_SHORT_READS.out.transcripts,
        SPADES_SAVES.out.transcripts,
        PATHEXTEND_CLUSTERS.out.transcripts,
        params.mgy,
        PREPARE_GENOME.out.fasta, PREPARE_GENOME.out.gtf
    )

    //
    // MODULE: Pipeline reporting
    //
    ch_software_versions
        .map { it -> if (it) [ it.baseName, it ] }
        .groupTuple()
        .map { it[1][0] }
        .flatten()
        .collect()
        .set { ch_software_versions }

    GET_SOFTWARE_VERSIONS (
        ch_software_versions.map { it }.collect()
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowClusterassembly.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report       = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
