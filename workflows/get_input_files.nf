// modules
include { PANORAMA_GET_FASTA } from "../modules/panorama"
include { PANORAMA_GET_SPECTRAL_LIBRARY } from "../modules/panorama"
include { PANORAMA_GET_SKYLINE_TEMPLATE } from "../modules/panorama"

workflow get_input_files {

   emit:
       fasta
       comet_params
       umpire_params

    main:

        if(params.fasta.startsWith("https://")) {
            PANORAMA_GET_FASTA(params.fasta)
            fasta = PANORAMA_GET_FASTA.out.panorama_file
        } else {
            fasta = file(params.fasta, checkIfExists: true)
        }

        if(params.comet_params.startsWith("https://")) {
            PANORAMA_GET_COMET_PARAMS(params.comet_params)
            comet_params = PANORAMA_GET_COMET_PARAMS.out.panorama_file
        } else {
            comet_params = file(params.comet_params, checkIfExists: true)
        }

        if(params.umpire_params.startsWith("https://")) {
            PANORAMA_GET_DIA_UMPIRE_PARAMS(params.umpire_params)
            umpire_params = PANORAMA_GET_DIA_UMPIRE_PARAMS.out.panorama_file
        } else {
            umpire_params = file(params.umpire_params, checkIfExists: true)
        }

}
