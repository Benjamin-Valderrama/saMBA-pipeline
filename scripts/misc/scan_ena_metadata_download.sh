#!/bin/bash

# Initialize variables
ACCESSION_FILE=""
DIRECTORY=""
failed_metadatas=()

# Function to display usage
usage() {
    echo "Usage: $0 -a <accessions_file> -d <directory>"
    echo "  -a, --accession    Path to the TSV file used as input for samba.sh"
    echo "  -d, --directory    Path to the directory used as output for samba.sh"

    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--accessions)
            ACCESSION_FILE="$2"
            shift 2
            ;;
        -d|--directory)
            DIRECTORY="${2%/}"  # Remove trailing slash if present
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Ensure both arguments are provided
if [[ -z "$ACCESSION_FILE" || -z "$DIRECTORY" ]]; then
    echo "Error: Both -a and -d options are required."
    usage
fi

# Define log directory and file paths
LOG_DIR="${DIRECTORY}/logs"
LOG_FILE="${LOG_DIR}/failed_metadata_downloads.log"

# Check if the accessions file exists
if [[ ! -f "$ACCESSION_FILE" ]]; then
    echo "Error: The accessions file '$ACCESSION_FILE' does not exist."
    exit 1
fi

# Check if the directory exists
if [[ ! -d "$DIRECTORY" ]]; then
    echo "Error: The directory '$DIRECTORY' does not exist."
    exit 1
fi

# Make a list of bioprojects with failed metadata download
bioprojects=$(tail -n +2 $ACCESSION_FILE | cut -f1 | sort -u)

for project in $bioprojects; do
#    echo "$project"

    n_samples_expected=$(grep "$project" "$ACCESSION_FILE" | wc -l)
    metadata_file="${DIRECTORY}/${project}/00.rawdata/fastq-run-info.tsv"

    if [[ -f "$metadata_file" ]]; then
        n_samples_w_metadata=$(tail -n +2 "$metadata_file" | wc -l)
    else
        n_samples_w_metadata=0
    fi

    # If project has more samples than metadata in ENA,
    # it's highly likely that the metadata download failed
    if [[ $n_samples_expected -gt $n_samples_w_metadata ]]; then
        failed_metadatas+=($project)
	echo "PRJ: $project; N samples expected: $n_samples_expected; N samples with metadata: $n_samples_w_metadata"
    fi

done


# Export the list of projects with failed metadata download
echo "study_accession" > "$LOG_FILE" # header of the file

for failed in "${failed_metadatas[@]}"; do
	echo $failed >> "$LOG_FILE"
done
