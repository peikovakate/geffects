`%>%` <- magrittr::`%>%`

parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-e", "--effects"), 
                               type = "character", 
                               default = "effects.tsv",
                               help="lead effects across conditions")
parser <- optparse::add_option(parser, c('-o', '--output'), 
                               default = "./",
                               type="character", 
                               help="output folder")
args = optparse::parse_args(parser)

effects_to_matricies = function(effects, replace_na_with = FALSE) {
  effects_matrix <- dplyr::select(effects, ends_with('.beta')) %>%
    dplyr::rename_all(function(x) { sub(".beta", "", x) })
  errors_matrix <- dplyr::select(effects, ends_with('.se')) %>%
    dplyr::rename_all(function(x) { sub(".se", "", x) })

  effects_matrix <- as.matrix(effects_matrix)
  errors_matrix <- as.matrix(errors_matrix)

  missing_values <- which(is.na(effects_matrix), arr.ind = TRUE)
  if (replace_na_with == "mean") {
    effects_matrix[missing_values] <- rowMeans(effects_matrix, na.rm = TRUE)[missing_values[, 1]]
    errors_matrix[missing_values] <- rowMeans(errors_matrix, na.rm = TRUE)[missing_values[, 1]]
  } else if (replace_na_with == "zero") {
    effects_matrix[missing_values] <- 0
    errors_matrix[missing_values] <- 1
  }
  return(list(beta = effects_matrix, se = errors_matrix))
}


effects <- readr::read_tsv(args$effects)
print(sprintf("File contains %i effects", nrow(effects)))

eqtls = effects_to_matricies(effects, "zero")

cor_method = "spearman"
cols.cor <- cor(eqtls$beta, method = cor_method)
write.table(cols.cor, file.path(args$output, sprintf("%s_cor_na_to_zero.txt", cor_method)))
pheatmap::pheatmap(cols.cor, fontsize = 12, border_color = NA, width = 12, height = 10, 
    filename = file.path(args$output, sprintf("%s_na_to_zero.png", cor_method)))

cor_method = "pearson"
cols.cor <- cor(eqtls$beta, method = cor_method)
write.table(cols.cor, file.path(args$output, sprintf("%s_cor_na_to_zero.txt", cor_method)))
pheatmap::pheatmap(cols.cor, fontsize = 12, border_color = NA, width = 12, height = 10, 
    filename = file.path(args$output, sprintf("%s_na_to_zero.png", cor_method)))
