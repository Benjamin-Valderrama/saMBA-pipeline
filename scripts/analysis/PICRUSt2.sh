#!/bin/bash

study_folder_path=$1

# activate PICRUSt2 environment
eval "$(micromamba shell hook --shell bash)"
micromamba activate picrust2

# run PICRUSt2 pipeline
nohup picrust2_pipeline.py \
	-s ${study_folder_path}/02.picrust2/input/otu_sequences.fasta \
	-i ${study_folder_path}/02.picrust2/input/otu_table.tsv \
	-o ${study_folder_path}/02.picrust2/output/ \
	-p 35 \
	--in_traits EC,KO \
	--no_pathways \
	--stratified > ${study_folder_path}/nohups/picrust2.out

# deactivate conda environment
micromamba deactivate
