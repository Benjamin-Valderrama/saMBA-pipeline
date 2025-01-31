suppressMessages(library(tidyverse))

# Read the path to the folder where all the subfolders with projects are stored
project_folder <- commandArgs(trailingOnly = TRUE)[1]
library_layout <- commandArgs(trailingOnly = TRUE)[2]

cat(paste0("\nlibrary layout: ", library_layout, "\n"))

# Read the file where the reads are tracked
if(library_layout == "paired_end"){
    # read track_reads_through_pipeline.tsv
    track_reads <- read.table(file = paste0(project_folder, "/01.dada2/track_reads_through_pipeline.tsv"),
                              sep = "\t", row.names = 1)
    
} else if(library_layout == "single_end"){
    # read SE_track_reads_through_pipeline.tsv
    track_reads <- read.table(file = paste0(project_folder, "/01.dada2/SE_track_reads_through_pipeline.tsv"),
			      sep = "\t", row.names = 1)
}


# Read the count table
if(library_layout == "paired_end"){
    # read PE count table
    count_table <- read.table(file = paste0(project_folder, "/01.dada2/count_table.tsv"),
			      sep = "\t", row.names = 1)

} else if(library_layout == "single_end"){
    # read SE count table
    count_table <- read.table(file = paste0(project_folder, "/01.dada2/SE_count_table.tsv"),
		              sep = "\t", row.names = 1)
}



# Identify samples with :
# (1) less than 10K non-chimeric reads
samples_with_many_chimera_reads <- track_reads %>%
    rownames_to_column("run_accession") %>%
    mutate(keep = nochim > 1e4) %>%
    filter(!keep) %>%
    pull(run_accession)

cat("samples with too many chimeric reads: \n")
cat(paste(samples_with_many_chimera_reads, collapse = "\n"))



# (2) more than 10% of the reads are classified to the Archea kingdom
samples_with_many_archaea <- count_table %>%
    rownames_to_column("asv") %>%
    mutate(asv_taxonomy = paste0(asv, "_", full_taxonomy)) %>%
    select(!c(asv, full_taxonomy)) %>%
    pivot_longer(cols = !asv_taxonomy,
                 names_to = "sample",
                 values_to = "abundance") %>%
    group_by(sample) %>%
    summarise(archaea_abundance = sum(abundance[grepl(x = asv_taxonomy, pattern = "Archaea;")]),
	      no_archaea_abundance = sum(abundance[!grepl(x = asv_taxonomy, pattern = "Archaea;")]),
	      .groups = "drop") %>% 
    mutate(perc_archaea = (archaea_abundance/(archaea_abundance + no_archaea_abundance))*100) %>%
    filter(perc_archaea > 10) %>% 
    pull(sample)

cat("\nsamples with too many archaea reads: \n")
cat(paste(samples_with_many_archaea, collapse = "\n"))


# (3) more than 10% of reads are unclassified at the Phylum level
samples_with_many_unassigned_phyla <- count_table %>%
    pivot_longer(!full_taxonomy,
		 names_to = "sample",
		 values_to = "abundance") %>%
    mutate(phylum = word(string = full_taxonomy, start = 2, end = 2, sep = ";")) %>%
    group_by(sample) %>%
    summarise(abundance_known_phyla = sum(abundance[!grepl(x = phylum, pattern = "NA")]),
	      abundance_unknown_phyla = sum(abundance[grepl(x = phylum, pattern = "NA")]),
	      .groups = "drop") %>%
    mutate(perc_unnasigned_phylum = (abundance_unknown_phyla/(abundance_unknown_phyla + abundance_known_phyla))*100) %>%
    filter(perc_unnasigned_phylum  > 10) %>%
    pull(sample)
    
cat("\nsamples with too many unassigned phyla: \n")
cat(paste(samples_with_many_unassigned_phyla, collapse = "\n"))



# Make a list of samples to remove (those with many chimeric reads, with many archaeas, or many unassigned kingdom)
samples_to_remove <- c(samples_with_many_chimera_reads, 
		       samples_with_many_archaea,
		       samples_with_many_unassigned_phyla) %>% 
	unique()


# Write the count table after removing the samples with many chimeras and many archaea
clean_count_table <- count_table %>%
    rownames_to_column("ASV") %>%
    select(!all_of(samples_to_remove))


# colnames in count table that are not in clean_count_table
cat("\nrun accessions not included in final clean_count_table: \n")

excluded_samples <- colnames(count_table)[!colnames(count_table) %in% colnames(clean_count_table)]
cat(paste(excluded_samples, collapse = "\n"))


# Write clean count table and list of removed samples
write_tsv(x = clean_count_table, file = paste0(project_folder, "/outputs/clean_count_table_asvs.tsv"))
write_lines(x = samples_to_remove, file = paste0(project_folder, "/logs/samples_removed_from_final_count_table.txt"))
