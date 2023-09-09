process MSCONVERT_FROM_RAW {
    storeDir "${params.mzxml_cache_directory}/${workflow.commitId}/${params.msconvert.do_demultiplex}/${params.msconvert.do_simasspectra}"
    label 'process_medium'
    label 'error_retry'
    container 'chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.23216-da81cda'

    input:
        path raw_file
        val do_demultiplex
        val do_simasspectra

    output:
        path("${raw_file.baseName}.mzXML"), emit: mzxml_file

    script:

    demultiplex_param = do_demultiplex ? '--filter "demultiplex  optimization=overlap_only massError=10.0ppm"' : ''
    simasspectra = do_simasspectra ? '--simAsSpectra' : ''

    """
    wine msconvert \
        -v \
        --zlib \
        --mzXML \
        --filter "peakPicking vendor msLevel=1-" \
        --64 ${simasspectra} ${demultiplex_param} \
        ${raw_file}
    """
}

process MSCONVERT_FROM_MGF {
    label 'process_medium'
    label 'error_retry'
    container 'quay.io/protio/msconvert_linux:3.0.23240'

    input:
        each path(mgf_file)

    output:
        path("${mgf_file.baseName}.mzXML"), emit: mzxml_file

    script:
    """
    msconvert \
        -v \
        --zlib \
        --mzXML \
        ${mgf_file}
    """
}
