// Modules
include { COMET } from "../modules/comet"
include { ADD_FASTA_TO_COMET_PARAMS } from "../modules/add_fasta_to_comet_params"
include { TPP } from "../modules/tpp"

workflow wf_comet_tpp {

    take:
        mzml_file_ch
        comet_params
        umpire_params
        fasta
        decoy_prefix
    
    main:

        ADD_FASTA_TO_COMET_PARAMS(comet_params, fasta)
        new_comet_params = ADD_FASTA_TO_COMET_PARAMS.out.comet_fasta_params

        COMET(mzml_file_ch, new_comet_params, fasta)

        TPP(COMET.out.pepxml.collect(), fasta, decoy_prefix, mzml_file_ch.collect())
}
