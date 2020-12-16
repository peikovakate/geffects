def helpMessage() {
    log.info "help message"
}

if (params.help) {
    helpMessage()
    exit 0
}

Channel.fromPath(params.susie_files)
    .ifEmpty { error "Cannot find any samples_path file in: ${params.samples_path}" }
    .splitCsv(header: false, sep: '\t', strip: true)
    .map{row -> row[0]}
    .set { build_cc } 

susie_files = Channel.fromPath(params.susie_files)

Channel.fromFilePairs("${params.sumstat_path}/*_ge.nominal.sorted.tsv.gz{,.tbi}")
    .set{sumstat}

process buildComponents {
    publishDir "${params.outdir}", mode: "copy"

    input:
    path y from build_cc.collect()
    path susie from susie_files

    output:
    path "cc.tsv" into query_samstat
    
    """
    Rscript $baseDir/bin/build_connected_components.R -m ${susie} 
    """
}

process querySumstat {
    memory '10 G'

    input:
    tuple val(qtl_group), path(sumstat), path(components) from sumstat.combine(query_samstat)

    output:
    path "${qtl_group}.tsv" into merge_sumstat
    // stdout into result

    script:
    """
    echo $qtl_group and ${sumstat[0]}
    Rscript $baseDir/bin/query_sumstat_with_tabix.R -v $components -q $qtl_group -s ${sumstat[0]} -r
    """
}

process mergeSumstat {
    memory '40 G'   
    publishDir "${params.outdir}", mode: "copy"

    input:
    path(qtl_group) from merge_sumstat.collect()

    output:
    path "cc_eqtls.tsv" into lead_effects

    script:
    """
    Rscript $baseDir/bin/merge_query_tabix.R -f . -o cc_eqtls.tsv
    """
}

process findLeadEffects {
    memory '20 G' 
    publishDir "${params.outdir}", mode: "copy"

    input:
    path eqtls from lead_effects

    output:
    path "lead_effects_na.tsv" into qtlgroup_similarity

    script:
    """
    Rscript $baseDir/bin/pick_lead_effects.R -s $eqtls -o ./
    """
}

process similarity {
    publishDir "${params.outdir}", mode: "copy"

    input:
    path lead_effects from qtlgroup_similarity

    output:
    path "pearson_cor_na_to_zero.txt"
    path "pearson_na_to_zero.png"
    path "spearman_cor_na_to_zero.txt"
    path "spearman_na_to_zero.png"

    script:
    """
    Rscript $baseDir/bin/similarity.R -e $lead_effects 
    """

}

process mash {
    time '20h'
    publishDir "${params.outdir}", mode: "copy"

    input:
    path lead_effects from qtlgroup_similarity
    path "utils2.R" from Channel.fromPath("$baseDir/bin/utils2.R")

    output:
    tuple path("mash.R"), path("data.R") into sharing
    
    script:
    
    """
    Rscript $baseDir/bin/mash.R -e $lead_effects
    """
}

process mash_sharing {
    time '20h'
    publishDir "${params.outdir}", mode: "copy"

    input:
    tuple path("mash.R"), path("data.R") from sharing

    output:
    path "mash_with_posteriors.R"
    path "sharing.R"
    
    script:
    
    """
    Rscript $baseDir/bin/mash_posterior.R
    """
}


// result.subscribe { println "$it" }