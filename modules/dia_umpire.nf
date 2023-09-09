def exec_java_command(mem) {
    def xmx = "-Xmx${mem.toGiga()-1}G"
    return "java -Djava.aws.headless=true ${xmx} -jar /usr/local/bin/DIA_Umpire.jar"
}

process DIA_UMPIRE {
    publishDir "${params.result_dir}/dia-umpire", failOnError: true, mode: 'copy'
    label 'process_high_constant'
    container 'quay.io/protio/dia-umpire:2.2.8'

    input:
        path mzxml_file
        path umpire_params_file

    output:
        path("${mzxml_file.baseName}_Q1.mgf"), emit: q1_mgf_file
        path("${mzxml_file.baseName}_Q2.mgf"), emit: q2_mgf_file
        path("${mzxml_file.baseName}_Q3.mgf"), emit: q3_mgf_file
        path("*.stdout"), emit: stdout
        path("*.stderr"), emit: stderr

    script:
    """
    # replace the number of threads in the DIA-Umpire params file with the number of threads available to this task
    sed 's/Thread\s*=\s*[0-9]*/Thread = ${task.cpus}/' ${umpire_params_file} > dia-umpire.updated.params

    echo "Running DIA-Umpire..."
    
    ${exec_java_command(task.memory)} ${mzxml_file} dia-umpire.updated.params \
        > >(tee "${mzxml_file.baseName}.stdout") 2> >(tee "${mzxml_file.baseName}.stderr" >&2)

    echo "DONE!" # Needed for proper exit
    """
}
