#!/bin/bash

study_folder=$1 # The right order of the arguments was given in the wraper.
accession=$2

echo "Downloading : ${accession}"

# the ${study_folder} variable is calling the entire pathway under the hood
fastq-dl --accession ${accession} \
	 --outdir "${study_folder}/00.rawdata" \
	 --silent \
	 --cpus 80 \
