`%>%` <- magrittr::`%>%`

parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-e", "--effects"),
  type = "character",
  default = "effects.tsv",
  help = "tsv with effects across conditions"
)
parser <- optparse::add_option(parser, c("-o", "--output"),
  default = "./",
  type = "character",
  help = "output directory"
)
args <- optparse::parse_args(parser)
print(args)

effects = readr::read_tsv(args$effects)
dir.create(args$output, recursive = T)

dplyr::select(effects, variant, molecular_trait_id, ends_with('.beta')) %>%
  dplyr::rename_all(function(x){sub(".beta$", "", x)}) %>%
  dplyr::rename(SNP = variant, Gene = molecular_trait_id) %>%
  readr::write_tsv(file.path(args$output, "slope.txt"))

dplyr::select(effects, variant, molecular_trait_id, ends_with('.se')) %>%
  dplyr::rename_all(function(x){sub(".se$", "", x)}) %>%
  dplyr::rename(SNP = variant, Gene = molecular_trait_id) %>%
  readr::write_tsv(file.path(args$output, "se.txt"))
