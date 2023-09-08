process TPP {
    publishDir "${params.result_dir}/tpp", failOnError: true, mode: 'copy'
    label 'process_high_constant'
    container 'spctools/tpp:version6.2.0'

    input:
        path pepxml_files
        path fasta_file
        path mzml_files
        path comet_params_file

    output:
        path("interact.pep.xml"), emit: peptide_prophet_pepxml_file
        path("interact.ptm.pep.xml"), emit: ptm_prophet_pepxml_file
        path("interact.ipro.ptm.pep.xml"), emit: inter_prophet_pepxml_file
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:

    pepxml_file_list = pepxml_files.join(" ")

    """
    # running peptideprophet commands
    InteractParser interact.pep.xml ${pepxml_file_list} \
    > >(tee "InteractParser.stdout") 2> >(tee "InteractParser.stderr" >&2)
    
    RefreshParser interact.pep.xml ${fasta_file} \
    > >(tee "RefreshParser.stdout") 2> >(tee "RefreshParser.stderr" >&2)
    
    # get the decoy prefix from the comet params file
    export DECOY_PREFIX=$(grep -oP 'decoy_prefix\s*=\s*\K\w+' comet_params_file)

    PeptideProphetParser interact.pep.xml MAXTHREADS=${task.cpus} MINPROB=0.1 NONPARAM BANDWIDTHX=2 CLEVEL=1 PPM ACCMASS NONPARAM ONEFVAL VMC EXPECTSCORE DECOY=\$DECOY_PREFIX \
    > >(tee "PeptideProphetParser.stdout") 2> >(tee "PeptideProphetParser.stderr" >&2)

    # running ptmprophet command
    PTMProphetParser \
       FRAGPPMTOL=50 \
       C:57.02146,MWFHCP:15.9949,H:22.03197,K:14.96328,K:-1.031634,KHC:156.11503,K:138.104465,K:54.010565,C:47.984744 \
       STATIC \
       NOSTACK \
       MAXTHREADS=${task.cpus} \
       MINPROB=0.1 \
       interact.pep.xml \
       interact.ptm.pep.xml \
       > >(tee "PTMProphetParser.stdout") 2> >(tee "PTMProphetParser.stderr" >&2)

    # running iprophet command
    InterProphetParser THREADS=${task.cpus} interact.ptm.pep.xml interact.ipro.ptm.pep.xml \
    > >(tee "InterProphetParser.stdout") 2> >(tee "InterProphetParser.stderr" >&2)
    """
}
