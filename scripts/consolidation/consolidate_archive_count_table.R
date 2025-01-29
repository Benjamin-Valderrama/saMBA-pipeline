suppressMessages(library(tidyverse))
suppressMessages(library(purrr))


analysed_projects_folder <- commandArgs(trailingOnly = TRUE)[1]

# Path to the count tables of every project aggregated up to the genus level
paths_to_genus_lvl_clean_count_tables <- list.files(path = analysed_projects_folder, 
	   pattern = "clean_count_table_genus.tsv", 
	   recursive = TRUE)


unwanted_taxonomies <- "Eukaryota;NA;NA;NA;NA;NA|Bacteria;NA;NA;NA;NA;NA|NA;NA;NA;NA;NA;NA"

# read the count tables from the list above, merge them and output the consolidated table
purrr::map(.x = paste0(analysed_projects_folder, paths_to_genus_lvl_clean_count_tables),
	   .f = ~ read_tsv(file = .x, show_col_types = FALSE)) %>%
	# remove eukaryotes and reads that couldn't be identified at the phylum level
        purrr::map(.x = .,
		   .f = ~ filter(.data = ., !grepl(x = full_taxonomy, pattern = unwanted_taxonomies))) %>%
	purrr::reduce(full_join, by = "full_taxonomy") %>%
	mutate(across(.cols = everything(), .fns = ~ifelse(is.na(.x), yes = 0, no = .x))) %>%
	write_tsv(x = ., 
		  file = paste0(analysed_projects_folder, "consolidated/archive_count_table.tsv"))
