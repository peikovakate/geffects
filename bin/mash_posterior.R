load("mash.R")
load("data.R")

print("Calc the posteriors")
m2 = mashr::mash(data, g=ashr::get_fitted_g(m), fixg=TRUE, algorithm.version="Rcpp")
save(m2, file = "mash_with_posteriors.R")

print("Estimate sharing")
sharing = mashr::get_pairwise_sharing(m2)
save(sharing, file = "sharing.R")
