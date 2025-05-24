suppressMessages(library(tidyverse))

# Read the path to the folder where all the subfolders with projects are stored
project_folder <- commandArgs(trailingOnly = TRUE)[1]
consolidated_folder <- paste0(project_folder, "consolidated")

# Read archive's genus-level count table
count_table <- read_tsv(file = paste0(consolidated_folder, "/genus_count_table.tsv"),
			show_col_type = FALSE) %>%
	column_to_rownames("full_taxonomy")
dim(count_table)

# This filtering process follows the guidelines described in the methods 
# section of PMID: 39848248 (see 'Datasets for analysis').

# Overview of things this sript does: 
# 1. Remove samples with <10k reads. [DONE]
# 2. Remove taxa with less than 80 reads across all remaining samples. [DONE]
# 3. Remove taxa present in less than 3 samples. [DONE]
# 4. Remove samples that now have <10k reads. [DONE]
# 5. Remove samples with >10% of taxa with unassigned phylum. [DONE]
# 6. Export clean count table [DONE]

# Note that different thresholds were used in steps 2 and 3, as the intention
# was to discard the same *proportion* of taxa, rather than using exactly
# the same thresholds described in PMID: 39848248.


# 1. Remove samples with <10k reads. (i.e., low sequencing depth)
# Count how many reads are on each sample
cat("Removing samples with less than 10k reads\n")

samples_to_keep <- colSums(count_table) >= 1e4
count_table <- count_table[ , samples_to_keep]

#sum(!samples_to_keep)
#dim(count_table)


# 2. Remove taxa with less than 80 reads across all remaining samples.
#    this matches removing 50% of genera as done in the HMC
cat("Removing taxa with low abundance across samples\n")

taxa_to_keep <- rowSums(count_table) >= 80
count_table <- count_table[taxa_to_keep , ]

#sum(!taxa_to_keep)
#dim(count_table)


# 3. Remove taxa present in less than 3 samples (e.g., taxa with low prevalence).
#    this removes 12% of the taxa, which is close to the 14% removed in the HMC
cat("Removing taxa with low prevalence\n")

# generate what will hold the prevalence table
prevalence_table <- count_table
# transform counts into prevalence (i.e., 1s or 0s)
prevalence_table[prevalence_table >= 1] <- 1

prevalent_taxa <- rowSums(prevalence_table) > 3
count_table <- count_table[prevalent_taxa , ]

#sum(!prevalent_taxa)
#dim(count_table)


# 4. After removing some taxas, the count of reads of some samples will drop.
#    Thus, we need to remove those that have <10k reads now.
#    Count how many reads are on each sample
cat("Removing samples with less than 10k reads again\n")

samples_to_keep <- colSums(count_table) >= 1e4
count_table <- count_table[, samples_to_keep]

#sum(!samples_to_keep)
#dim(count_table)


# 5. Remove samples with >10% of taxa with unassigned kingdome and phylum
cat("Removing samples with >10% of taxa without phylum assigned\n")

# get rows with unwanted taxa
unwanted <- "^Archaea;NA;*|^Eukaryota;NA;*|^Bacteria;NA;*|^NA;NA;*"
unwanted_taxa <- grepl(pattern = unwanted, x = rownames(count_table))
unwanted_count_table <- count_table[unwanted_taxa, ]

# calculate how many counts per sample go to unwanted taxa
unwanted_counts <- colSums(unwanted_count_table)

# remove samples with more than 10% of counts in unwanted taxa
total_counts <- colSums(count_table)
unwanted_props <- (unwanted_counts / total_counts)
samples_to_keep <- unwanted_props <= 0.1
count_table <- count_table[, samples_to_keep]

#sum(!samples_to_keep)
#dim(count_table)


# 6. Export cleaned count table
clean_count_table_path = paste0(consolidated_folder, "/clean_genus_count_table.tsv")
cat(paste0("Exporting clean count table to: ", clean_count_table_path, "\n"))

#dim(count_table)

count_table <- count_table %>% rownames_to_column("full_taxonomy")
write_tsv(x = count_table, 
	  file = clean_count_table_path)
