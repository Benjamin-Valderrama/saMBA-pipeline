suppressMessages(library(tidyverse))
suppressMessages(library(purrr))

###################
#### VARIABLES ####
###################

projects_folder <- commandArgs(trailingOnly = TRUE)[1]
#projects_folder

# Paths to ASV-level count tables from each project
paths_to_asv_ct <- list.files(path = projects_folder,
           pattern = "ASV_count_table.tsv",
	   recursive = TRUE)
# Get only the count tables in the outputs folder
paths_to_asv_ct <- paths_to_asv_ct[grepl(x = paths_to_asv_ct, pattern = "/outputs/")]
paths_to_asv_ct <- paste(projects_folder, paths_to_asv_ct, sep = "/")

# Paths to Genus-level count tables from each project
paths_to_genus_ct <- list.files(path = projects_folder,
           pattern = "genus_count_table.tsv",
	   recursive = TRUE)
# Get only the count tables in the outputs folder
paths_to_genus_ct <- paths_to_genus_ct[grepl(x = paths_to_genus_ct, pattern = "/outputs/")]
paths_to_genus_ct <- paste(projects_folder, paths_to_genus_ct, sep = "/")

###################
#### FUNCTIONS ####
###################
log <- function(path){
    cat(paste("Analysing:", path, "\n"))
}

consolidate_table <- function(vector_with_paths, level){

    # level is either:
    # 'full_taxonomy', for genus-level
    # 'sequence', for ASV-level
    log(vector_with_paths)

    # Read the count tables
    count_tables_list <- vector_with_paths %>%
	map(.x = .,
	    .f = ~ read_tsv(file = .x, show_col_types = FALSE))

    if(level == "sequence"){
	count_tables_list <- count_tables_list %>%
	    map(.x = .,
		.f = ~ select(.data = .x, !full_taxonomy)
		)
    }

    consolidated_table <- count_tables_list %>%    
	# Join all count tables by 'level'
        reduce(.f = full_join, by = level) %>%
	# Convert NAs (absent taxonomies) to 0s
	mutate(across(.cols = everything(), 
		      .fns = ~ifelse(is.na(.x), yes = 0, no = .x))) %>%
	relocate(matches(level))

    # return
    consolidated_table
}

# Consolidate ASV-level count table and export
consolidated_asv_ct <- consolidate_table(paths_to_asv_ct, "sequence")
write_tsv(x = consolidated_asv_ct, 
	  file = paste0(projects_folder, "consolidated/asv_count_table.tsv"))

# Consolidate genus-level count table and export
consolidated_genus_ct <- consolidate_table(paths_to_genus_ct, "full_taxonomy")
write_tsv(x = consolidated_genus_ct,
          file = paste0(projects_folder, "consolidated/genus_count_table.tsv"))
