suppressMessages(library(tidyverse))

# Read the path to the folder where all the subfolders with projects are stored
project_folder <- commandArgs(trailingOnly = TRUE)[1]
consolidated_folder <- paste0(project_folder, "consolidated")

# Read archive's genus-level count table
count_table <- read_tsv(file = paste0(consolidated_folder, "/genus_count_table.tsv"),
			show_col_type = FALSE)

# As described in the methods section (see 'Datasets for analysis') in PMID: 39848248
# Overview of things this sript does: 
# 1. Remove samples with <10k reads. [DONE]
# 2. Remove taxa with less than 1k reads across all remaining samples. [DONE]
# 3. Remove taxa present in less than 100 samples. [DONE]
# 4. Remove samples that now have <10k reads. [DONE]
# 5. Remove samples with >10% of Archaea or unassigned phylum. [DONE]
# 6. Export clean count table


# 1. Remove samples with <10k reads. (i.e., low sequencing depth)
# Count how many reads are on each sample
cat("Removing samples by number of reads\n")
counts_per_sample <- count_table %>% 
    select(!full_taxonomy) %>%
    colSums()

# Keep samples with >10k reads
samples_to_keep <- counts_per_sample[counts_per_sample >= 1e4]
cols_to_keep <- c("full_taxonomy", names(samples_to_keep))
count_table <- count_table[, cols_to_keep]


# 2. Remove taxa with less than 1k reads across all remaining samples.
cat("Removing taxa with low abundance across samples\n")
counts_per_taxa <- count_table %>%
    select(!full_taxonomy) %>%
    rowSums()

taxa_to_keep <- counts_per_taxa >= 1e3
count_table <- count_table[taxa_to_keep, ]


# 3. Remove taxa present in less than 100 samples (e.g., taxa with low prevalence).
# transform counts into prevalence (i.e., 1s or 0s)
cat("Removing taxa with low prevalence\n")
prevalence_table <- count_table %>%
    # remove taxonomy as the row order in both tables will remain the same
    select(!full_taxonomy) %>%
    mutate(across(everything(), ~ifelse(.x > 0, yes = 1, no = 0)))

taxa_to_keep <- rowSums(prevalence_table) >= 1e2
count_table <- count_table[taxa_to_keep, ]


# 4. After removing some taxas, the count of reads of some samples will drop.
# Thus, we need to remove those that have <10k reads now.
# Count how many reads are on each sample
cat("Removing samples by reads again\n")
# re calculate counts per sample
counts_per_sample <- count_table %>%
    select(!full_taxonomy) %>%
    colSums()

# Keep samples with >10k reads
samples_to_keep <- counts_per_sample[counts_per_sample >= 1e4]
cols_to_keep <- c("full_taxonomy", names(samples_to_keep))
count_table <- count_table[, cols_to_keep]


# 5. Remove samples with >10% of Archaea or unassigned phylum
# We want to remove Archaeas, Eukaryots, Bacteria anything with unasigned phyla,
# and taxonomies without kingdom and phyla
cat("Removing samples with high percentage of unwatend taxa\n")
unwanted <- "^Archaea;*|^Eukaryota;*|^Bacteria;NA|^NA;"

unwanted_taxa <- grepl(pattern = unwanted, x = count_table$full_taxonomy)
# print this line below for diagnositcs:
# count_table[unwanted_taxa, ] |> as.data.frame()

unwanted_taxa_per_sample <- count_table %>%
    filter(unwanted_taxa) %>%
    select(!full_taxonomy) %>%
    colSums()

total_taxa_per_sample <- count_table %>%
    select(!full_taxonomy) %>%
    colSums()

percentage_of_unwanted <- (unwanted_taxa_per_sample / total_taxa_per_sample) * 100
samples_with_acceptable_percentage_of_unwanted <- percentage_of_unwanted <= 10
cols_to_keep <- c("full_taxonomy", names(samples_with_acceptable_percentage_of_unwanted))
count_table <- count_table[, cols_to_keep]


# 6. Export cleaned count table
clean_count_table_path = paste0(consolidated_folder, "/clean_genus_count_table.tsv")

cat(paste0("Exporting clean count table to: ", clean_count_table_path, "\n"))
write_tsv(x = count_table, 
	  file = clean_count_table_path)
