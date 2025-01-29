#!/bin/bash

# read in the output folder
output=$1
mkdir ${output}/consolidated


# use R to consolidate the files generated for each project included

# clean count tables of each project are consolidated into one table
echo "PROGRESS -- consolidating count tables"
Rscript saMBA/consolidation/consolidate_archive_count_table.R $output/ &> $output/nohups/count_tables_consolidation.log &
last_pid=$!
wait $last_pid

# ENA file reports of each project are consolidated into one table
echo "PROGRESS -- consolidating ENA file reports"
Rscript saMBA/consolidation/consolidate_ena_filereports.R $output/ &> $output/nohups/ena_filereports_consolidation.log &
last_pid=$!
wait $last_pid

# files tracking the reads of each sample through each step of the DADA2 pipeline are consolidated
echo "PROGRESS -- consolidating 'track_reads_through_pipeline' files"
Rscript saMBA/consolidation/consolidate_track_reads.R $output/ &> $output/nohups/track_reads_consolidation.log &
last_pid=$!
wait $last_pid

# we merge file reports and track_reads files. This removes all the samples in the ENA metadata
# that weren't included in the actual analysis.
echo "PROGRESS -- merge ENA file reports and track_reads_through_pipeline"
Rscript saMBA/consolidation/consolidate_metadata.R $output/ &> $output/nohups/metadata_consolidation.log &
last_pid=$!
wait $last_pid

# we can remove the consolidated filereports and track_read files
