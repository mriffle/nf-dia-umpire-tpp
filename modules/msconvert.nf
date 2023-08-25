process MSCONVERT {
    storeDir "${params.mzml_cache_directory}"
    label 'process_medium'
    label 'error_retry'
    container 'chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.23216-da81cda'

    input:
        path raw_file
        path dia_umpire_params
        val do_demultiplex
        val do_simasspectra

    output:
        path("${raw_file.baseName}.mzML"), emit: mzml_file
        path("dia-umpire.updated.params"), emit: dia_params_updated

    script:

    demultiplex_param = do_demultiplex ? '--filter "demultiplex  optimization=overlap_only massError=10.0ppm"' : ''
    simasspectra = do_simasspectra ? '--simAsSpectra' : ''

    """
    # replace the number of threads in the DIA-Umpire params file with the number of threads available to this task
    sed 's/Thread\s*=\s*[0-9]*/Thread = ${task.cpus}/' ${dia_umpire_params} > dia-umpire.updated.params

    wine msconvert \
        -v \
        --zlib \
        --mzML \
        --64 ${simasspectra} ${demultiplex_param} \
        --filter "peakPicking vendor msLevel=1-" \
        --filter "diaUmpire params=dia-umpire.updated.params" \
        --filter "titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"""^<SourcePath^>""", NativeID:"""^<Id^>"""" \
        ${raw_file}

    """

    stub:
    """
    touch ${raw_file.baseName}.mzML
    """
}
