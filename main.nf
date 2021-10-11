#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/clusterassembly
========================================================================================
    Github : https://github.com/nf-core/clusterassembly
    Website: https://nf-co.re/clusterassembly
    Slack  : https://nfcore.slack.com/channels/clusterassembly
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

// params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { CLUSTERASSEMBLY } from './workflows/clusterassembly'

//
// WORKFLOW: Run main nf-core/clusterassembly analysis pipeline
//
workflow NFCORE_CLUSTERASSEMBLY {
    CLUSTERASSEMBLY ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_CLUSTERASSEMBLY ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
