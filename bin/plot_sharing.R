load("sharing.R")

pheatmap::pheatmap(sharing, fontsize=12, border_color=NA, filename="mash_sharing_heatmap.png", width=12, height=10)

sharing_tbl = reshape2::melt(sharing, value.name = "sharing")
sharing_tbl = dplyr::as_tibble(sharing_tbl)
readr::write_tsv(sharing_tbl, "sharing.tsv")