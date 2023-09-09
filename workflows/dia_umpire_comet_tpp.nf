// Modules
include { COMET } from "../modules/comet"
include { ADD_FASTA_TO_COMET_PARAMS } from "../modules/add_fasta_to_comet_params"
include { TPP } from "../modules/tpp"
include { UPLOAD_TO_LIMELIGHT } from "../modules/limelight_upload"
include { CONVERT_TO_LIMELIGHT_XML } from "../modules/limelight_xml_convert"
include { DIA_UMPIRE } from "../modules/dia_umpire"
include { MSCONVERT_FROM_MGF } from "../modules/msconvert"

workflow wf_dia_umpire_comet_tpp {

    take:
        mzxml_file_ch
        comet_params
        umpire_params
        fasta
        peptide_prophet_params
        ptm_prophet_mods
        ptm_prophet_params
    
    main:

        ADD_FASTA_TO_COMET_PARAMS(comet_params, fasta)
        new_comet_params = ADD_FASTA_TO_COMET_PARAMS.out.comet_fasta_params

        // run DIA-Umpire
        DIA_UMPIRE(mzxml_file_ch, umpire_params)
        combined_mgf_channel = DIA_UMPIRE.out.q1_mgf_files
                                .merge(DIA_UMPIRE.out.q2_mgf_files)
                                .merge(DIA_UMPIRE.out.q3_mgf_files)
        MSCONVERT_FROM_MGF(Channel.fromList(combined_mgf_channel))

        // run comet
        dda_like_mzxml_file_ch = MSCONVERT_FROM_MGF.out.mzxml_file
        COMET(dda_like_mzxml_file_ch, new_comet_params, fasta)

        // run TPP
        TPP(
            COMET.out.pepxml.collect(), 
            fasta, 
            dda_like_mzxml_file_ch.collect(), 
            comet_params,
            peptide_prophet_params,
            ptm_prophet_mods,
            ptm_prophet_params
        )

        // Upload to Limelight
        if (params.limelight_upload) {

            CONVERT_TO_LIMELIGHT_XML(
                TPP.out.inter_prophet_pepxml_file, 
                fasta, 
                comet_params
            )

            UPLOAD_TO_LIMELIGHT(
                CONVERT_TO_LIMELIGHT_XML.out.limelight_xml,
                dda_like_mzxml_file_ch.collect(),
                fasta,
                params.limelight_webapp_url,
                params.limelight_project_id,
                params.limelight_search_description,
                params.limelight_search_short_name,
                params.limelight_tags,
            )
        }

}
