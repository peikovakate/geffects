cat_path <- "/gpfs/hpc/projects/eQTLCatalogue/susie-finemapping/eQTL_Catalogue_r3/susie"
gtex_path <- "/gpfs/hpc/projects/eQTLCatalogue/susie-finemapping/GTEx_v7/susie"
pattern <- "_ge.purity_filtered.txt.gz"

list_files <- function(dir_path, pattern) {
  files <- list.files(dir_path, full.names = F, pattern = pattern)
  data <- dplyr::tibble(
    path = file.path(dir_path, files),
    qtl_group = sub(pattern, "", files)
  )
  return(data)
}

eqtl_cat <- list_files(cat_path, pattern)
gtex <- list_files(gtex_path, pattern)
data <- dplyr::bind_rows(eqtl_cat, gtex)
readr::write_tsv(data, "susie_ge.tsv", col_names = F)