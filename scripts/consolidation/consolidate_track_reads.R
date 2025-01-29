suppressMessages(library(tidyverse))
suppressMessages(library(purrr))

folder_with_analysed_projects <- commandArgs(trailingOnly = TRUE)[1]

# onject to store the consolidated track_reads_through_pipeline dataframe
consolidated_track_reads <- data.frame(input = numeric(),
				       filtered = numeric(),
				       denoisedF = numeric(),
				       denoisedR = numeric(),
				       nochim = numeric(),
				       analysis_layout = character())


# for each project analysed...
for(project in dir(path = folder_with_analysed_projects, pattern = "PRJ")){
#	print(project)

	# get path to final count tables. They are produced only if all quality checks are successful
        final_count_tables_vector <- list.files(paste0(folder_with_analysed_projects, "/", project, "/outputs"))

	# get path to all files produced by every dada2 analysis ran on the project
	dada2_output_files_vector <- list.files(paste0(folder_with_analysed_projects, "/", project, "/01.dada2"))
#	print(dada2_output_files_vector)

	# from all dada2 outputs, we keep the 'track_reads_through_pipeline' files
        track_reads_files_vector <- dada2_output_files_vector[grepl(x = dada2_output_files_vector,
								    pattern = "track_reads_through_pipeline")]
#	print(track_reads_files_vector)


	# Now we want to check if the project passed the cuality checks, to consolidate
	# the 'track_reads..' files of those projects that were successfully analysed.
	# i.e., we want a non-empty output folder for the project
	if (length(final_count_tables_vector) > 1) {
		

#		print("sucessfully analysed")
		# if more than 1 track_reads_files was produced, then the project was analysed as SE
		# because this is only possible if a PE project is reanalysed as SE.
		if (length(track_reads_files_vector) > 1) {
			
#			print("project re-analysed as SE")
			track_reads_df <- read.delim(paste0(folder_with_analysed_projects, "/", project, "/01.dada2/SE_track_reads_through_pipeline.tsv"),
						     sep = "\t")

			# we want to merge together track_reads files from PE and SE.
			# as track_reads files for SE projects don't have a 'denoiseR'
			# column, with add one filled with NA
			track_reads_df <- track_reads_df %>%
						mutate(denoisedR = NA,
						       analysis_layout = "SINGLE") %>%
						relocate(input, filtered, denoisedF, denoisedR, nochim)


		# If the project was successfully analysed but only 1 'track_reads' file is produced
		# we need to determine if it was PE or SE.
		} else {

			# check if track_reads file has "SE" in its name
			if ( grepl(x = track_reads_files_vector, pattern = "SE_") ){
#				print("project analysed once as SE")
				track_reads_df <- read.delim(paste0(folder_with_analysed_projects, "/", project, "/01.dada2/SE_track_reads_through_pipeline.tsv"),
	                                                     sep = "\t")

				# again, we need to add the column denoisedR, which is absent in SE projects
				track_reads_df <- track_reads_df %>%
						mutate(denoisedR = NA, 
						       analysis_layout = "SINGLE") %>%
						relocate(input, filtered, denoisedF, denoisedR, nochim)


			# if not SE, then it was a PE project
			} else {

#				print("project analysed once as PE")
				track_reads_df <- read.delim(paste0(folder_with_analysed_projects, "/", project, "/01.dada2/track_reads_through_pipeline.tsv"),
                                                             sep = "\t") %>%
						  mutate(analysis_layout = "PAIRED") %>%
						  # fix order of columns and rename 'merged' to 'nochim'
						  select(input, filtered, denoisedF, denoisedR, nochim=merged, analysis_layout)

			}

		}

		# now SE and PE projects share the same number of columns and
		# each column has the same name. We just bind one after the other
		consolidated_track_reads <- rbind(consolidated_track_reads,
						  track_reads_df)
	}

}

#dim(consolidated_track_reads)
#head(consolidated_track_reads)


# export the consolidated 'track_files_through_pipeline.tsv' files
consolidated_track_reads %>%
	rownames_to_column("run_accession") %>%
	write_tsv(file = paste0(folder_with_analysed_projects, "/consolidated/track_reads.tsv"))

