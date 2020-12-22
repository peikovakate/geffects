suppressWarnings(library(plyr))
suppressWarnings(library(optparse))
suppressWarnings(library(readr))

option_list = list(make_option(c("-O", "--outputdir"), type = "character", default='output/', help="output directory", metavar="character"),
		   make_option(c("-f", "--savefn"), type = "character", default='choose_para_preliminary.txt', help="filename to save the output", metavar="character"))
opt = parse_args(OptionParser(option_list=option_list))


files = list.files(opt$outputdir, pattern="*.RData", recursive=T)
result = NULL
for(file in files){
        print(file)
        load(file)
        result = rbind(result, c(K, alpha1, lambda1, ncol(FactorM), L_sparsity, F_sparsity))
}

result = as.data.frame(result)
colnames(result) = c("K", "alpha1", "lambda1", "nfactor", "L_sparsity", "F_sparsity")
write_tsv(result, file.path(opt$outputdir, opt$savefn))


