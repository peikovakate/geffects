def helpMessage() {
    log.info "help message"
}

if (params.help) {
    helpMessage()
    exit 0
}

Channel.fromPath(params.effects)
    .ifEmpty { error "Cannot find file in: ${params.effects}" }
    .set { build_input } 

Channel.fromPath(params.colors)
    .ifEmpty { error "Cannot find file in: ${params.colors}" }
    .set { qtlgroup_colors }

factors = Channel.of(20, 25, 30)
alpha = Channel.of(800, 900, 1000, 1100, 1200)
lambda = Channel.of(800, 900, 1000, 1100, 1200)

process buildMatricies {
    container = "quay.io/peikova/factorization:dev"
    publishDir "${params.outdir}/factorization", mode: "copy"

    input:
    path effects from build_input

    output:
    tuple path("slope.txt"), path("se.txt") into params_search
    tuple path("slope.txt"), path("se.txt") into mapping
    
    """
    Rscript $baseDir/bin/factorization/build_matricies.R -e $effects 
    """
}

process factorisation {
    beforeScript "ln -s $baseDir/bin/factorization/sn_spMF/ ."

    label 'process_long'
    errorStrategy 'ignore'
    container = "quay.io/peikova/factorization:dev"
    publishDir "${params.outdir}/factorization/grid_search", mode: "copy"

    when:
    !params.mapping

    input:
    tuple path(slope), path(se) from params_search
    path colors from qtlgroup_colors
    each fact from factors
    each lamb from lambda
    each alph from alpha
    each r from Channel.of(1..(params.second_level ? params.runs : 1))

    output:
    path("sn_spMF_K${fact}_a1${alph}_l1${lamb}/*") into gather_results

    script:
    if (!params.second_level) {
        """
        Rscript $baseDir/bin/factorization/sn_spMF/run_MF.R -k $fact -a $alph -l $lamb -t ${params.iter} -x $slope -w $se -O ./ -s $colors
        """
    } else {
        """
        Rscript $baseDir/bin/factorization/sn_spMF/run_MF.R -k $fact -a $alph -l $lamb -t ${params.iter} \
            -x $slope -w $se -O ./ -s $colors -c 1 -r $r
        """
    }

}

process gather {
    beforeScript "ln -s $baseDir/bin/factorization/sn_spMF/ ."
    container = "quay.io/peikova/factorization:dev"
    publishDir "${params.outdir}/factorization/grid_search", mode: "copy"

    when:
    !params.mapping

    input:
    path matrix from gather_results.collect()

    output:
    path params.second_level ? "second_level_results.tsv" : "first_level_results.tsv"

    script:
    if (!params.second_level) {
        """
        Rscript $baseDir/bin/factorization/sn_spMF/tune_parameters_preliminary.R -O . -f first_level_results.tsv
        """
    } else {
        """
        Rscript $baseDir/bin/factorization/sn_spMF/tune_parameters.R -O . -f second_level_results.tsv
        """
    }
}


process mapping {
    beforeScript "ln -s $baseDir/bin/factorization/mapping/ . && ln -s $baseDir/bin/factorization/sn_spMF/ ."
    publishDir "${params.outdir}/factorization/mapping", mode: "copy"
    container = "quay.io/peikova/factorization:dev"

    when:
    params.mapping

    input:
    tuple path(slope), path(se) from mapping
    path(files) from Channel.fromPath("${params.matrix_folder}/${params.mapping_matrix}").collect()

    output:
    path("*")

    script:
    """
    Rscript $baseDir/bin/factorization/mapping/lm.R -f ${params.mapping_matrix} -x $slope -w $se -d ./ -m ./
    """
}