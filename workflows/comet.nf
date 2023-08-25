// Modules
include { MSCONVERT } from "../modules/msconvert"
include { COMET } from "../modules/comet"
include { ADD_FASTA_TO_COMET_PARAMS } from "../modules/add_fasta_to_comet_params"

workflow wf_comet {

    take:
        mzml_file_ch
        comet_params
        umpire_params
        fasta
    
    main:

        // modify comet.params to specify search database
        ADD_FASTA_TO_COMET_PARAMS(comet_params, fasta)
        new_comet_params = ADD_FASTA_TO_COMET_PARAMS.out.comet_fasta_params

        COMET(mzml_file_ch, new_comet_params, fasta)

}
