def helpMessage(){
    log.info "help message"
}

if (params.help) {
    helpMessage()
    exit 0
}


Channel.fromPath(params.susie_files)
    .ifEmpty { error "Cannot find any samples_path file in: ${params.samples_path}" }
    .splitCsv(header: false, sep: '\t', strip: true)
    .map{row -> [row[0], row[0]] }
    .set { build_cc } 

process buildComponents{
    input:
    tuple val(x), path("$x") from build_cc.collect()

    ouput:
    
    """
    ls 
    """
}