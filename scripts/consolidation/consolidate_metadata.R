suppressMessages(library(tidyverse))

folder_with_analysed_projects <- commandArgs(trailingOnly = TRUE)[1]

file_reports <- read_tsv(file = paste0(folder_with_analysed_projects, "consolidated/ena_file_reports.tsv"), show_col_type = FALSE)
track_reads <- read_tsv(file = paste0(folder_with_analysed_projects, "consolidated/track_reads.tsv"), show_col_type = FALSE)


# inner join is used because track_reads only uses the info for samples included in final compendium,
# whereas file reports has information for all the samples downloaded, even if they are low quality.

#print(paste("FR", dim(file_reports)))
#print(paste("TR", dim(track_reads)))

merged <- inner_join(x = file_reports,,
		     y = track_reads,
		     by = "run_accession")

write_tsv(x = merged, file = paste0(folder_with_analysed_projects, "consolidated/metadata.tsv"))
