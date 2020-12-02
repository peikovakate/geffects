def helpMessage(){
    log.info "help message"
}

if (params.help) {
    helpMessage()
    exit 0
}

process buildComponents{
    
}