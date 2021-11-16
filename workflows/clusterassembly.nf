/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
// WorkflowClusterassembly.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [
    params.input
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

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check' addParams( options: [:] )
include { BRANCH_SEQ } from '../subworkflows/local/branch_seq' addParams ( options: [:] )
include { SPADES_DEV } from '../modules/local/spades_dev/main' addParams ( options: modules['spades_dev'])

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

def cat_fastq_options = modules['cat_fastq']
if ( !params.save_merged_fastq ) { cat_fastq_options['publish_files'] = false }

def multiqc_options   = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC  } from '../modules/nf-core/modules/fastqc/main'  addParams( options: modules['fastqc'] )
include { MULTIQC } from '../modules/nf-core/modules/multiqc/main' addParams( options: multiqc_options )
include { CAT_FASTQ } from '../modules/nf-core/modules/cat/fastq/main' addParams( options: cat_fastq_options )

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
    )

    //
    // SUBWORKFLOW: Concatenate sequence files from the same sample if required (separately for each type of data)
    //
    INPUT_CHECK.out
    .map {
        meta, list ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, list ] }
    .groupTuple(by: [0])
    .branch {
        meta, list ->
            single : list.size() == 1
                return [ meta, list.flatten() ]
            multiple: list.size() > 1
                return [ meta, list.flatten() ]
    }
    .set { ch_seq }

    CAT_FASTQ (
        ch_seq.multiple
    )
    .reads
    .mix(ch_seq.single)
    .set { ch_cat_seq }
    ch_software_versions = ch_software_versions.mix(CAT_FASTQ.out.versions.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Split input sequences into short reads, long reads and database sequences
    //
    BRANCH_SEQ (
        ch_cat_seq
    )

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        BRANCH_SEQ.out.short_reads
    )
    ch_software_versions = ch_software_versions.mix(FASTQC.out.version.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Join short reads, long reads and db sequences channels by sample id
    // [ meta_id, [ fastq_1, fastq_2 ], fasta, fasta ]
    ch_short = BRANCH_SEQ.out.short_reads
    .map { meta, list ->
        sample = meta.id
        [sample, list] }
    ch_long = BRANCH_SEQ.out.long_reads
    .map { meta, list ->
        sample = meta.id
        [sample, list] }
    ch_db = BRANCH_SEQ.out.db_seq
    .map { meta, list ->
        sample = meta.id
        [sample, list] }
    all_by_sample = ch_short.join(ch_long).join(ch_db)

    //
    // MODULE: Run SPAdes with short reads and long sequences (long reads and database transcripts)
    //
    SPADES_DEV (
        all_by_sample
    )
    ch_software_versions = ch_software_versions.mix(SPADES_DEV.out.version.first().ifEmpty(null))

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
