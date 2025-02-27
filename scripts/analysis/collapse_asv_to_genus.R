suppressMessages(library(tidyverse))

cat("PROGRESS -- Collapsing ASVs from clean count table to genus")

project_folder <- commandArgs(trailingOnly = TRUE)[1] 


# import ASV-level count table
asv_count_table <- read.delim(file = paste0(project_folder, "/outputs/ASV_count_table.tsv"))


# collapse ASV-abundances by full taxonomic information
asv_count_table %>% 
    select(!sequence) %>%
    summarise(across(where(is.numeric), .fn = ~sum(.x, na.rm = TRUE)), 
	      .by = full_taxonomy) %>%
    relocate(full_taxonomy) %>%
    write_tsv(x = ., file = paste0(project_folder, "/outputs/genus_count_table.tsv"))
