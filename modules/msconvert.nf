process MSCONVERT_FROM_RAW {
    storeDir "${params.mzml_cache_directory}/${workflow.commitId}/${params.msconvert.do_demultiplex}/${params.msconvert.do_simasspectra}"
    label 'process_medium'
    label 'error_retry'
    container 'chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.23216-da81cda'

    input:
        path raw_file
        val do_demultiplex
        val do_simasspectra

    output:
        path("${raw_file.baseName}.mzML"), emit: dia_mzml_file

    script:

    demultiplex_param = do_demultiplex ? '--filter "demultiplex  optimization=overlap_only massError=10.0ppm"' : ''
    simasspectra = do_simasspectra ? '--simAsSpectra' : ''

    """
    wine msconvert \
        -v \
        --zlib \
        --mzML \
        --filter "peakPicking vendor msLevel=1-" \
        --64 ${simasspectra} ${demultiplex_param} \
        ${raw_file}
    """

    stub:
    """
    touch ${raw_file.baseName}.mzML
    """
}

process MSCONVERT_DIA_UMPIRE {
    label 'process_high'
    label 'process_long'
    label 'error_retry'
    container 'quay.io/protio/msconvert_linux:3.0.23240'

    input:
        path dia_mzml_file
        path dia_umpire_params

    output:
        path("${raw_file.baseName}.mzML"), emit: dda_mzml_file

    script:

    demultiplex_param = do_demultiplex ? '--filter "demultiplex  optimization=overlap_only massError=10.0ppm"' : ''
    simasspectra = do_simasspectra ? '--simAsSpectra' : ''

    """
    # replace the number of threads in the DIA-Umpire params file with the number of threads available to this task
    sed 's/Thread\s*=\s*[0-9]*/Thread = ${task.cpus}/' ${dia_umpire_params} > dia-umpire.updated.params

    msconvert \
        -v \
        --zlib \
        --mzML \
        --filter "diaUmpire params=dia-umpire.updated.params" \
        --filter "titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:\\"<SourcePath>\\", NativeID:\\"<Id>\\"" \
        ${dia_mzml_file}
    """

}