suppressMessages(library(tidyverse))
 
projects_folder <- commandArgs(trailingOnly = TRUE)[1]

# read ASVs count tables
asv_ct_path <- paste0(projects_folder, "consolidated/asv_count_table.tsv")
asv_ct <- read_tsv(file = asv_ct_path, show_col_types = FALSE)
# Make ASV file
sequences <- asv_ct$sequence
fasta <- paste0("> ASV ",1:nrow(asv_ct), "\n",
                sequences)
# Export file
write_lines(x = fasta, file = paste0(projects_folder, "consolidated/ASVs.fasta"))
