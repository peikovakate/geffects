source("utils2.R")
`%>%` <- magrittr::`%>%`

parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-e", "--effects"), 
                               type = "character", 
                               help="tsv with effects, output from pick_lead_effects.R script")
parser <- optparse::add_option(parser, c('-p', '--pc_number'),
                               type="integer",
                               default = 5,
                               help = "principle component number")
args = optparse::parse_args(parser)

effects_file = args$effects

effects <- readr::read_tsv(effects_file)
nrow(effects)

eqtls = effects_to_matricies(effects, replace_na_with="zero")

alpha_value = 1
data   = mashr::mash_set_data(eqtls$beta, eqtls$se, alpha=alpha_value)
m.1by1 = mashr::mash_1by1(data, alpha=alpha_value)
strong = mashr::get_significant_results(m.1by1, 0.01)
U.c    = mashr::cov_canonical(data)

print("Compute PCA covariance matrix")
U.pca = mashr::cov_pca(data, args$pc_number, strong)

suppressWarnings({
    print("Compute extreme deconcolution covariance matrix")
    U.ed = mashr::cov_ed(data, U.pca, strong)    
})

print("Fit the model")
m = mashr::mash(data, U.ed, outputlevel = 1,  algorithm.version="Rcpp")
save(m, file = "mash.R")
save(data, file = "data.R")



