def helpMessage(){
    log.info "help message"
}

if (params.help) {
    helpMessage()
    exit 0
}


Channel.fromPath(params.samples_path)
    .ifEmpty { error "Cannot find any samples_path file in: ${params.samples_path}" }
    .splitCsv(header: false, sep: '\t', strip: true)
    .map{row -> row[0] }
    .set { build_cc } 

process buildComponents{
    input:
    path(file), stageAs: file from build_cc.collect()

    """
    ls
    """
}