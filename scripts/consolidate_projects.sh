#!/bin/bash

# read in the output folder
output=$1
output="${output%/}" # trail last '/' if present
mkdir ${output}/consolidated

# Set path to folder with the scripts used in saMBA
SCRIPTS_FOLDER="$(dirname "$(realpath "$0")")" # Folder with all scripts
CONSOLIDATION_SCRIPTS="${SCRIPTS_FOLDER}/consolidation" # Folder with scripts used in the analysis of one project


# Consolidate ASV- and Genus-level count tables
echo "PROGRESS -- consolidating count tables"
Rscript ${CONSOLIDATION_SCRIPTS}/archive_count_table.R $output/ > $output/logs/count_tables_consolidation.log 2>&1
last_pid=$!
wait $last_pid

# Consolidate ASVs fasta file from ASV-level count table
echo "PROGRESS -- consolidating ASVs fasta file"
Rscript ${CONSOLIDATION_SCRIPTS}/ASV_fasta.R $output/
last_pid=$!
wait $last_pid

# INSDC metadatas are consolidated
echo "PROGRESS -- consolidating INSDC file reports"
Rscript ${CONSOLIDATION_SCRIPTS}/insdc_filereports.R $output/ > $output/logs/insdc_filereports_consolidation.log 2>&1
last_pid=$!
wait $last_pid

# files tracking the reads of each sample through each step of the DADA2 pipeline are consolidated
echo "PROGRESS -- consolidating 'track_reads_through_pipeline' files"
Rscript ${CONSOLIDATION_SCRIPTS}/track_reads.R $output/ > $output/logs/track_reads_consolidation.log 2>&1
last_pid=$!
wait $last_pid

# join consolidated file reports and track_reads files.
# This removes all the samples in the ENA metadata that weren't included in the actual analysis.
echo "PROGRESS -- merge INSDC file reports and track_reads_through_pipeline"
Rscript ${CONSOLIDATION_SCRIPTS}/metadata.R $output/ > $output/logs/metadata_consolidation.log 2>&1
last_pid=$!
wait $last_pid
