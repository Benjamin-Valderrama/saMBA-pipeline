suppressMessages(library(tidyverse))

# Read from analysis.sh
study_folder <- commandArgs(trailingOnly = TRUE)[1]
library_layout <- commandArgs(trailingOnly = TRUE)[2]

# Check if read properly
#cat(library_layout)


# Determine input file based on library layout
if(library_layout == "paired_end"){
	file_tracking_reads = "/01.dada2/track_reads_through_pipeline.tsv"

} else if(library_layout == "single_end"){
	file_tracking_reads = "/01.dada2/SE_track_reads_through_pipeline.tsv"
}

#cat(file_tracking_reads)

# Read file with the status of the number of reads per step of the DADA2 pipeline
dada2_diagnostic <- read.delim(file = paste0(study_folder, file_tracking_reads),
	   header = TRUE,
           row.names = 1,
           sep = "\t")



##############
# Functions  #
##############

#' Quality check 1 :
#' Fails if non-chimeric reads are less than 50% of input reads
quality_check_1 <- function(df){

#	total <- df$input
#	nochim <- df$nochim
#	nochim_percentage <- (nochim/total)*100
#	pass_filter_1 <- nochim_percentage < 50
#       return(pass_filter_1)

	df %>%
	  summarise(total_input = sum(input),
		    total_nochimeras = sum(nochim)) %>%
	  mutate(percentage_of_nochimeras = (total_nochimeras/total_input) * 100,
                 pass_filter_1 = ifelse(percentage_of_nochimeras >= 50,
                                        yes = TRUE,
                                        no = FALSE)) %>%
	  pull(pass_filter_1)
}


#' PAIRED END Quality check 2 :
#' Fails if 5 out of the first 10 samples have more than 25% of chimera reads.
#' As this is a paired end layout, we use merged sequences to calculate the % of chimeras.
PE_quality_check_2 <- function(df){
	df %>%
	# get first 10 samples
	head(n = 10) %>%
	# Calculate the percentage of chimeras per sample
	mutate(percentage_of_chimera = (1 - (nochim/merged)) * 100,
               more_than_25perc_of_chimera = ifelse(test = percentage_of_chimera > 25,
                                                    yes = TRUE,
                                                    no = FALSE)) %>%
	# Get the number of samples with more than 25% of chimeras
	summarise(num_of_failed_samples = sum(more_than_25perc_of_chimera)) %>%
	# Check if that number is lower than 5
	mutate(pass_filter_2 = ifelse(test = num_of_failed_samples < 5,
                                      yes = TRUE,
                                      no = FALSE)) %>%
        pull(pass_filter_2)
}


#' SINGLE END Quality check 2 :
#' Fails if 5 out of the first 10 samples have more than 25% of chimera reads.
#' As this is a single end layout, we use denoised forward reads to calculate the % of chimeras.
SE_quality_check_2 <- function(df){
        df %>%
        # get first 10 samples
        head(n = 10) %>%
        # Calculate the percentage of chimeras per sample
        mutate(percentage_of_chimera = (1 - (nochim/denoisedF)) * 100,
               more_than_25perc_of_chimera = ifelse(test = percentage_of_chimera > 25,
                                                    yes = TRUE,
                                                    no = FALSE)) %>%
        # Get the number of samples with more than 25% of chimeras
        summarise(num_of_failed_samples = sum(more_than_25perc_of_chimera)) %>%
        # Check if that number is lower than 5
        mutate(pass_filter_2 = ifelse(test = num_of_failed_samples < 5,
                                      yes = TRUE,
                                      no = FALSE)) %>%
        pull(pass_filter_2)
}






############
# Analysis #
############

# Check if quality checks are passed or not
pass_quality_check_1 <- quality_check_1(dada2_diagnostic)


if(library_layout == "paired_end"){
	pass_quality_check_2 <- PE_quality_check_2(dada2_diagnostic)

} else if(library_layout == "single_end"){
	pass_quality_check_2 <- SE_quality_check_2(dada2_diagnostic)
}

quality_check_report <- paste0("QC 1 - nonchimeric reads > 50% of total reads: ", pass_quality_check_1, "\n",
			       "QC 2 - 5 out of 10 first samples with < 25 chimeric reads : ", pass_quality_check_2)




# Export report to nohups
# If there is no report (i.e., first time dada2 runs)
if(!file.exists(paste0(study_folder, "/logs/QC_report.log"))){

	write_lines(x = quality_check_report,
		    file = paste0(study_folder, "/logs/QC_report.log"))

} else {
	# If there was a report already...#
	write_lines(x = quality_check_report,
                    file = paste0(study_folder, "/logs/QC_report_rerun.log"))
}




# Determine if the analysis was successful or if it needs to be re done (based on library layout)
# cat("Final decision")

# If both quality checks are ok
if(pass_quality_check_1 & pass_quality_check_2) {
	cat("PASSED")

# If failed to pass both qualitychecks:
} else if(!pass_quality_check_1 & !pass_quality_check_2) {
	cat("PROGRESS -- FAILED : <50% OF READS DENOISED & >5 OF THE FIRST 10 SAMPLES HAD >25% OF CHIMERAS")

# If one is ok and the other is not:
} else if(any(c(pass_quality_check_1, pass_quality_check_2))){

	 if(pass_quality_check_1){
		# then second QC failed
		cat("PROGRESS -- FAILED : >5 OF THE FIRST 10 SAMPLES HAD >25% OF CHIMERAS")

        } else if (pass_quality_check_2){
		# then first QC failed
                cat("PROGRESS -- FAILED : <50% OF READS DENOISED")
        }
}
