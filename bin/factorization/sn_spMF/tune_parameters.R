source("sn_spMF/cophenet.R")
source("sn_spMF/collect_results.R")
suppressWarnings(library(plyr))
suppressWarnings(library(optparse))

option_list = list(
	make_option(c("-O", "--outputdir"), type = "character", default='output/', help="output directory with matricies folders", metavar="character"),
	make_option(c("-f", "--savefn"), type = "character", default='choose_para.txt', help="filename to save the output", metavar="character"),
	make_option(c("-r", "--runs"), type = "integer", default=30, help="number of runs"))
opt = parse_args(OptionParser(option_list=option_list))


result = NULL

files = list.files(opt$outputdir)
print(files)
rdata_files = files[grep("sn_spMF_K[0-9]+_a1[0-9]+_l1[0-9]+", files)]
patterns = unique(gsub("_Run[0-9]+.RData", "", rdata_files))
for(pattern in patterns){
	print(dir)
	pattern = sub("sn_spMF_K", "", pattern)
	pattern = sub("_a1", " ", pattern)
	pattern = sub("_l1", " ", pattern)
	params = strsplit(pattern, " ")[[1]]
	params = as.numeric(params)
	K = params[1]
	alpha1 = params[2]
	lambda1 = params[3]
	rowi = collect_results(opt$outputdir, K, alpha1, lambda1, opt$runs)
	if(!is.null(rowi)){
		result = rbind(result, rowi)
	}
}


result = as.data.frame(result)
colnames(result) = c("K", "alpha1", "lambda1", "coph", "correlation", "nfactor", "optimal_run", "optimal_obj")
result = result[order(result$coph), ]
readr::write_tsv(result, opt$savefn)


