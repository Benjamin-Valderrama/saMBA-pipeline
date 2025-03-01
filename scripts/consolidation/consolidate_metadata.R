suppressMessages(library(tidyverse))

projects_folder <- commandArgs(trailingOnly = TRUE)[1]

###############
## FUNCTIONS ##
###############
log <- function(path){
    cat(paste("Analysing:", path, "\n"))
}

# get consolidated file reports and track_reads
file_reports_path <- paste0(projects_folder, "consolidated/insdc_file_reports.tsv")
track_reads_path <- paste0(projects_folder, "consolidated/track_reads.tsv")

# read the consolidated files
log(file_reports_path)
file_reports <- read_tsv(file = file_reports_path, show_col_type = FALSE)

log(track_reads_path)
track_reads <- read_tsv(file = track_reads_path, show_col_type = FALSE)

# While track_reads only uses the info for samples included in final compendium,
# file reports has information for all the samples in the bioproject 
# (including those not downloaded). Thus, thanks to inner_join we can get the 
# info in INSDC for the analysed samples.
merged <- inner_join(x = file_reports,
		     y = track_reads,
		     by = "run_accession")

write_tsv(x = merged, file = paste0(projects_folder, "consolidated/metadata.tsv"))
