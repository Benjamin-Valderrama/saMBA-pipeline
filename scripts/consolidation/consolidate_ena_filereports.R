suppressMessages(library(tidyverse))
suppressMessages(library(purrr))


folder_with_analysed_projects <- commandArgs(trailingOnly = TRUE)[1]


# path to the file reports for every project 
paths_to_file_reports <- list.files(path = folder_with_analysed_projects, 
	   pattern = "insdc-metadata-run-info.tsv", 
	   recursive = TRUE)
#print(paths_to_file_reports)


# read the file reports of each project, select columns of interest and merge them into one dataframe
filereports_together <- purrr::map(.x = paste0(folder_with_analysed_projects, paths_to_file_reports),
	   .f = ~ read_tsv(file = .x, show_col_types = FALSE)) %>%
	purrr::map(.f = ~ select(.data = .x, study_accession, run_accession, original_library_layout = library_layout)) %>%
	dplyr::bind_rows()
#print(filereports_together)


# export the table with merged filereports
filereports_together %>% 
	write_tsv(x = ., file = paste0(folder_with_analysed_projects, "consolidated/ena_file_reports.tsv"))
