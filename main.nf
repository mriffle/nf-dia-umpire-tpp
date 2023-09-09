#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// modules
include { PANORAMA_GET_FASTA } from "./modules/panorama"
include { PANORAMA_GET_COMET_PARAMS } from "./modules/panorama"
include { PANORAMA_GET_RAW_FILE } from "./modules/panorama"
include { PANORAMA_GET_RAW_FILE_LIST } from "./modules/panorama"

// Sub workflows
include { get_input_files } from "./workflows/get_input_files"
include { get_mzxmls } from "./workflows/get_mzxmls"
include { wf_dia_umpire_comet_tpp } from "./workflows/dia_umpire_comet_tpp"

//
// The main workflow
//
workflow {

    get_input_files()                              // get input files
    get_mzxmls()                                   // get mzxmls

    // set up some convenience variables
    fasta = get_input_files.out.fasta
    comet_params = get_input_files.out.comet_params
    umpire_params = get_input_files.out.umpire_params
    mzxml_ch = get_mzxmls.out.mzxml_ch

    wf_dia_umpire_comet_tpp(
        mzxml_ch,
        comet_params,
        umpire_params,
        fasta,
        params.peptide_prophet_params,
        params.ptm_prophet_mods,
        params.ptm_prophet_params
    )
}

//
// Used for email notifications
//
def email() {
    // Create the email text:
    def (subject, msg) = EmailTemplate.email(workflow, params)
    // Send the email:
    if (params.email) {
        sendMail(
            to: "$params.email",
            subject: subject,
            body: msg
        )
    }
}

//
// This is a dummy workflow for testing
//
workflow dummy {
    println "This is a workflow that doesn't do anything."
}

// Email notifications:
workflow.onComplete {
    try {
        email()
    } catch (Exception e) {
        println "Warning: Error sending completion email."
    }
}
