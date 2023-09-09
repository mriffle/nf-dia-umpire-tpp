// modules
include { PANORAMA_GET_RAW_FILE } from "../modules/panorama"
include { PANORAMA_GET_RAW_FILE_LIST } from "../modules/panorama"
include { MSCONVERT_FROM_RAW } from "../modules/msconvert"

workflow get_mzxmls {

    emit:
       mzxml_ch

    main:

        if(params.spectra_dir.contains("https://")) {

            spectra_dirs_ch = Channel.from(params.spectra_dir)
                                    .splitText()               // split multiline input
                                    .map{ it.trim() }          // removing surrounding whitespace
                                    .filter{ it.length() > 0 } // skip empty lines

            // get raw files from panorama
            PANORAMA_GET_RAW_FILE_LIST(spectra_dirs_ch, params.spectra_dir)

            placeholder_ch = PANORAMA_GET_RAW_FILE_LIST.out.raw_file_placeholders.transpose()
            PANORAMA_GET_RAW_FILE(placeholder_ch)
            
            mzxml_ch = MSCONVERT_FROM_RAW(
                PANORAMA_GET_RAW_FILE.out.panorama_file,
                params.msconvert.do_demultiplex,
                params.msconvert.do_simasspectra
            )
            

        } else {

            file_glob = params.spectra_glob
            spectra_dir = file(params.spectra_dir, checkIfExists: true)
            data_files = file("$spectra_dir/${file_glob}")

            if(data_files.size() < 1) {
                error "No files found for: $spectra_dir/${file_glob}"
            }

            raw_files = data_files.findAll { it.name.endsWith('.raw') }

            if(raw_files.size() < 1) {
                error "No raw files found in: $spectra_dir"
            }

            mzxml_ch = MSCONVERT_FROM_RAW(
                    Channel.fromList(raw_files),
                    params.msconvert.do_demultiplex,
                    params.msconvert.do_simasspectra
            )

        }
}
