#!/bin/bash

# read in the output folder
output=$1
mkdir ${output}/consolidated

# Set path to folder with the scripts used in saMBA
SCRIPTS_FOLDER="$(dirname "$(realpath "$0")")" # Folder with all scripts
CONSOLIDATION_SCRIPTS="${SCRIPTS_FOLDER}/consolidation" # Folder with scripts used in the analysis of one project


# use R to consolidate the files generated for each project included

# clean count tables of each project are consolidated into one table
echo "PROGRESS -- consolidating count tables"
Rscript ${CONSOLIDATION_SCRIPTS}/consolidate_archive_count_table.R $output/ &> $output/nohups/count_tables_consolidation.log &
last_pid=$!
wait $last_pid

# ENA file reports of each project are consolidated into one table
echo "PROGRESS -- consolidating ENA file reports"
Rscript ${CONSOLIDATION_SCRIPTS}/consolidate_ena_filereports.R $output/ &> $output/nohups/ena_filereports_consolidation.log &
last_pid=$!
wait $last_pid

# files tracking the reads of each sample through each step of the DADA2 pipeline are consolidated
echo "PROGRESS -- consolidating 'track_reads_through_pipeline' files"
Rscript ${CONSOLIDATION_SCRIPTS}/consolidate_track_reads.R $output/ &> $output/nohups/track_reads_consolidation.log &
last_pid=$!
wait $last_pid

# we merge file reports and track_reads files. This removes all the samples in the ENA metadata
# that weren't included in the actual analysis.
echo "PROGRESS -- merge ENA file reports and track_reads_through_pipeline"
Rscript ${CONSOLIDATION_SCRIPTS}/consolidate_metadata.R $output/ &> $output/nohups/metadata_consolidation.log &
last_pid=$!
wait $last_pid

# we can remove the consolidated filereports and track_read files
