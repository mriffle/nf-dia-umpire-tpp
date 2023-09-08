// Modules
include { COMET } from "../modules/comet"
include { ADD_FASTA_TO_COMET_PARAMS } from "../modules/add_fasta_to_comet_params"
include { TPP } from "../modules/tpp"
include { UPLOAD_TO_LIMELIGHT } FROM "../modules/limelight_upload"
include { CONVERT_TO_LIMELIGHT_XML } FROM "../modules/limelight_xml_convert"

workflow wf_comet_tpp {

    take:
        mzml_file_ch
        comet_params
        umpire_params
        fasta
        peptide_prophet_params
        ptm_prophet_mods
        ptm_prophet_params
    
    main:

        ADD_FASTA_TO_COMET_PARAMS(comet_params, fasta)
        new_comet_params = ADD_FASTA_TO_COMET_PARAMS.out.comet_fasta_params

        COMET(mzml_file_ch, new_comet_params, fasta)

        TPP(
            COMET.out.pepxml.collect(), 
            fasta, 
            mzml_file_ch.collect(), 
            comet_params,
            peptide_prophet_params,
            ptm_prophet_mods,
            ptm_prophet_params
        )

        if (params.limelight_upload) {

            CONVERT_TO_LIMELIGHT_XML(
                COMET.out.pepxml.collect(), 
                fasta, 
                comet_params
            )

            UPLOAD_TO_LIMELIGHT(
                CONVERT_TO_LIMELIGHT_XML.out.limelight_xml,
                mzml_file_ch.collect(),
                fasta,
                params.limelight_webapp_url,
                params.limelight_project_id,
                params.limelight_search_description,
                params.limelight_search_short_name,
                params.limelight_tags,
            )
        }

}
