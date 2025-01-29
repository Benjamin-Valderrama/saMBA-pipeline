suppressMessages(library(tidyverse))

cat("PROGRESS -- Collapsing ASVs from clean count table to genus")

project_folder <- commandArgs(trailingOnly = TRUE)[1] 


# import count table after removing samples
clean_count_table <- read_tsv(file = paste0(project_folder, "/outputs/clean_count_table_asvs.tsv"), 
			      show_col_types = FALSE)


# check how did they consolidate datasets from different proejects
clean_count_table %>% 
    select(!ASV) %>%
    group_by(full_taxonomy) %>%
    summarise(across(where(is.numeric), .fn = ~sum(.x, na.rm = TRUE))) %>%
    filter(!is.na(full_taxonomy)) %>%
    relocate(full_taxonomy) %>%
    write_tsv(x = ., file = paste0(project_folder, "/outputs/clean_count_table_genus.tsv"))


