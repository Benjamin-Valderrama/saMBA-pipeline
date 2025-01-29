################################################
####   ARGUMENTS GIVEN BY THE MAIN SCRIPT   ####
study_folder <- commandArgs(trailingOnly = TRUE)[1]

################################################

library(dada2, quietly = TRUE)


pathFq <- paste0(study_folder, "/00.rawdata")

filtpathFq <- file.path(pathFq, "filtered") # Filtered forward files will go into the pathF/filtered/ subdirectory

# if files have the "_1.fast.gz" pattern they are analysed as originally being paired end.
# otherwise, they are analysed as originally single end
if(length(list.files(pathFq, pattern = "_1.fastq.gz")) > 0){
	originally_paired_end <- TRUE
} else {
	originally_paired_end <- FALSE
}


if(originally_paired_end){
	fastqFs <- sort(list.files(pathFq, pattern = "_1.fastq.gz"))
	
} else {
	fastqFs <- sort(list.files(pathFq, pattern = ".fastq.gz"))
}


# FILTER AND TRIMMING
print("FILTER AND TRIMMING ...")
out <- filterAndTrim(fwd=file.path(pathFq, fastqFs), filt=file.path(filtpathFq, fastqFs),
              compress=TRUE, verbose=TRUE, multithread=TRUE,

	      # According to the methods section of PMID:37873416
	      trimLeft=0, trimRight=0,
	      minLen=50, maxLen=Inf, maxN=0, rm.phix=TRUE, truncQ=0)


# Remove samples where all reads failed to pass the filter.
#
# These samples won't be used anyway, and keeping them will make
# our script to fail later on, when tracking the reads of each
# sample through the entire script.
out <- out[out[, "reads.out"] > 0, ]


if(originally_paired_end){
        filtFs <- list.files(filtpathFq, pattern = "_1.fastq.gz", full.names = TRUE)
        sample.names <- sapply(strsplit(basename(filtFs), "_"), `[`, 1)

} else {
        filtFs <- list.files(filtpathFq, pattern = ".fastq.gz", full.names = TRUE)
        sample.names <- sapply(strsplit(basename(filtFs), "[.]"), `[`, 1)
}

names(filtFs) <- sample.names



# LEARN ERROR RATES 
print("LEARN ERROR RATES ...")
set.seed(01021997)

# forward 
errF <- learnErrors(filtFs, nbases=1e8, multithread=TRUE)



# DEREPLICATION
print("DEREPLICATION ...")

# sample inference and merger of paired-end reads
#mergers <- vector("list", length(sample.names))
#names(mergers) <- sample.names

dadasF <- vector("list", length(sample.names))
names(dadasF) <- sample.names

#dadasR <- vector("list", length(sample.names))
#names(dadasR) <- sample.names



# Derreplication and merging of forward and reverse reads
for(sam in sample.names){
  cat("Processing:", sam, "\n")

  derepF <- derepFastq(filtFs[[sam]])
  ddF <- dada(derepF, err=errF, multithread=TRUE, verbose=FALSE)
  dadasF[[sam]] <- ddF
  
  #derepR <- derepFastq(filtRs[[sam]])
  #ddR <- dada(derepR, err=errR, multithread=TRUE, verbose=FALSE)
  #dadasR[[sam]] <- ddR
  
  #merger <- mergePairs(ddF, derepF, ddR, derepR, minOverlap=20)
  #mergers[[sam]] <- merger
}
rm(derepF)



# CONSTRUCT SEQUENCE TABLE AND REMOVE CHIMERAS
seqtab <- makeSequenceTable(dadasF)


print("REMOVE CHIMERAS ...")
# check the error here
seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE)


# TRACK READS THROUGH THE PIPELINE
print("TRACK READS THROUGH THE PIPELINE ...")

getN <- function(x){sum(getUniques(x))}
track <- cbind(out, sapply(dadasF, getN), rowSums(seqtab.nochim))

colnames(track) <- c("input", "filtered", "denoisedF", "nochim")
rownames(track) <- sample.names

write.table(x = track, file = paste0(study_folder, "/01.dada2/SE_track_reads_through_pipeline.tsv"),
	    sep = "\t", quote = FALSE,
            row.names = TRUE, col.names = TRUE)



# ASSIGN TAXONOMY
print("ASSIGN TAXONOMY ...")
tax <- assignTaxonomy(seqtab.nochim, "/data/databases/SILVA/silva_nr99_v138.2_train_set.fa.gz", multithread=TRUE, tryRC = TRUE)

# the taxonomy ranks that can't be assigned are forced to be a "NA" string instead of NA value
# this will make the removal of chloroplasts and mitochondria easier as the NA (ASV unassigned at certain taxonomic level)
# won't be removed from the count table
tax[is.na(tax)] <- "NA"


saveRDS(object = tax, file = paste0(study_folder, "/01.dada2/SE_taxonomy.rds"))
saveRDS(object = seqtab.nochim, file = paste0(study_folder, "/01.dada2/SE_seqtab_nochim.rds"))


count_table_tax <- as.data.frame(t(rbind(seqtab.nochim, t(tax))))
count_table_tax$full_taxonomy <- paste0(count_table_tax[, "Kingdom"], ";" ,
                                        count_table_tax[, "Phylum" ], ";" ,
                                        count_table_tax[, "Class"  ], ";" ,
                                        count_table_tax[, "Order"  ], ";" ,
                                        count_table_tax[, "Family" ], ";" ,
                                        count_table_tax[, "Genus"  ])

# remove mitochondria and chloroplasts
count_table_tax <- count_table_tax[count_table_tax$Order != "Chloroplast" ,]
count_table_tax <- count_table_tax[count_table_tax$Family != "Mitochondria", ]


# remove ranking-specific columns
taxonomic_ranks_names <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus")
count_table_tax <- count_table_tax[, !colnames(count_table_tax) %in% taxonomic_ranks_names]

# create a clean count table as an output
clean_count_table_tax <- count_table_tax

# next line added to debug:
#clean_count_table_tax$sequence <- rownames(clean_count_table_tax)
row.names(clean_count_table_tax) <- paste0("ASV", 1:nrow(clean_count_table_tax))




# DADA2 OUTPUTS
print("WRITING DADA2 OUTPUTS ...")
write.table(x = clean_count_table_tax,
	    file = paste0(study_folder, "/01.dada2/SE_count_table.tsv"),
	    sep = "\t", quote = FALSE,
	    row.names = TRUE, col.names = TRUE)



# GENERATING THE OUTPUTS FOR PICRUSt2
#print("WRITING PICRUSt2's INPUT FILES")

#write.table(x = clean_count_table_tax,
#	    file = paste0(study_folder, "/02.picrust2/input/otu_table_with_taxonomy.csv"),
#	    row.names = FALSE, quote = FALSE, sep = ",")

#write.table(x = clean_count_table_tax[, -ncol(clean_count_table_tax)],
#           file = paste0(study_folder, "/02.picrust2/input/otu_table.tsv"),
#           row.names = FALSE, quote = FALSE, sep = "\t")

#write.table(x = paste0(">ASV", 1:nrow(count_table_tax), "\n",
#                       rownames(count_table_tax)),
#            file = paste0(study_folder, "/02.picrust2/input/otu_sequences.fasta"),
#            quote = FALSE, row.names = FALSE, col.names = FALSE)



# SAVING THE IMAGE OF THE R ENVIRONMENT
save.image(file = paste0(study_folder, "/01.dada2/SE_environment.RData"))
#print("DADA2 FINISHED")
