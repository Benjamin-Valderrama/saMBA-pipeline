suppressMessages(library(tidyverse))
suppressMessages(library(purrr))

projects_folder <- commandArgs(trailingOnly = TRUE)[1]

# path to the filereports for every project 
paths_to_filereports <- list.files(path = projects_folder, 
	   pattern = "insdc-metadata-run-info.tsv", 
	   recursive = TRUE)
#print(paths_to_filereports)

###############
## FUNCTIONS ##
###############

log <- function(path){
    cat(paste("Analysing:", path, "\n"))
}

read_and_harmonise <- function(path){

    log(path)

    # read insdc file report
    file_report <- read_tsv(file = path, show_col_types = FALSE)
    # harmonise it
    file_report <- select(.data = file_report,
			  study_accession,
                          run_accession,
                          original_library_layout = library_layout)
}

# read the file reports of each project, select columns of interest and merge them into one dataframe
filereports_df <- map(.x = paste0(projects_folder, paths_to_filereports),
	              .f = read_and_harmonise) %>%
		    list_rbind()
#print(filereports_df)


# export filereports as single df 
write_tsv(x = filereports_df,
	  file = paste0(projects_folder, "consolidated/insdc_file_reports.tsv"))
