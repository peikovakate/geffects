`%>%` <- magrittr::`%>%`

parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-v", "--variants"), 
                               type = "character", 
                               help="file with variants, should have phenotype_id, variant_id, cc_id columns")
parser <- optparse::add_option(parser, c('-s', "--sumstat_file"), 
                               type = "character", 
                               help = "eqtl catalogue sumstat file, with molecular_id column")
parser <- optparse::add_option(parser, c('-q', '--qtl_group'),
                               default = "",
                               type="character", 
                               help = "study qtl group name")
parser <- optparse::add_option(parser, c('-o', '--output_dir'), default="./",
                               type="character", 
                               help = "output dir")
parser <- optparse::add_option(parser, 
                               c('-t', '--tabix'), 
                               type="character", 
                               default = "tabix",
                               help="path to tabix cmd tool")
parser <- optparse::add_option(parser, type="logical",
                               c("-r", "--rm_rsid"), action = "store_true", default = FALSE,
                               help = "Remove rsid column and duplicates from results [default]")
parser <- optparse::add_option(parser, c("-c", "--coords"),
                               default = NA, type="character",
                               help="File with coordinates to fetch")
args = optparse::parse_args(parser)

print(args)

sumstat_file <- args$sumstat_file
qtl_group <- args$qtl_group
pairs_file <- args$variants
output_dir <- args$output_dir
tabix_path <-  args$tabix
rm_rsid <- args$rm_rsid
coords_file <- args$coords

print(qtl_group)

if(!dir.exists(output_dir)){
  dir.create(output_dir, recursive = T)
}

temp_sumstat_file = file.path(output_dir, paste0(qtl_group, "_temp.tsv"))

variants = readr::read_tsv(pairs_file, col_types = readr::cols())

# in case of file with variants has inconsitent name (microarray vs rna-seq)
if("phenotype_id" %in% names(variants)){
  variants = dplyr::rename(variants, molecular_trait_id = phenotype_id)  
}
if("variant_id" %in% names(variants)){
  variants = dplyr::rename(variants, variant = variant_id)
}

# if file with coordinates to query was not provided
if(is.na(coords_file)){
  # getting the name of file with coords (CHR, POS)
  # coords_file = sprintf("%s_coords.tsv", sub('\\.tsv$', '', pairs_file))
  coords_file = "coords.tsv"
  
  coords = variants %>% dplyr::select(chr, pos) %>% 
    dplyr::rename(CHROM = chr, POS=pos) %>% 
    dplyr::distinct(.keep_all = T) %>% 
    dplyr::arrange(CHROM, POS)
  
  readr::write_tsv(coords, coords_file, col_names = F)
}

# set file with variant coordinates as input and redirect output of tabix to temporary file
input = paste(sumstat_file, "-R", coords_file, ">", temp_sumstat_file)
sumstat_out = system2(tabix_path, args=input, stdout = T)

# rnaseq columns
eqtl_colnames = c(
  "molecular_trait_id",
  "chromosome",
  "position",
  "ref",
  "alt",
  "variant",
  "ma_samples",
  "maf",
  "pvalue",
  "beta",
  "se",
  "type",
  "ac",
  "an", 
  "r2",
  "molecular_trait_object_id",
  "gene_id",
  "median_tpm",
  "rsid"
)

eqtl_col_types = readr::cols(alt = "c", ref = "c", type="c", rsid="c", r2="c")

# read results in temp file
# eqtl_colnames and eqtl_col_types are defined in utils.R file
sumstat = readr::read_tsv(temp_sumstat_file, col_names = eqtl_colnames, col_types = eqtl_col_types)

if("cc_id" %in% colnames(variants)){
  cols_to_join = c("molecular_trait_id", "variant", "cc_id")
}else {
  cols_to_join = c("molecular_trait_id", "variant")
}

sumstat = dplyr::inner_join(sumstat, 
                            variants[cols_to_join], 
                            by=c("variant", "molecular_trait_id"))
sumstat = dplyr::mutate(sumstat, qtl_group = qtl_group)

print(head(sumstat))

# remove duplicates with rsid
if(rm_rsid){
  sumstat = dplyr::select(sumstat, -rsid) %>% dplyr::distinct(.keep_all = T)  
}

# delete temp file
file.remove(temp_sumstat_file)

print(qtl_group)
print(paste("Found pairs:", nrow(sumstat)))

readr::write_tsv(sumstat, file.path(output_dir, paste0(qtl_group, ".tsv")))

