#!/bin/bash

# Initialize variables
ACCESSION_FILE=""
DIRECTORY=""
downloaded_accessions=()
expected_accessions=()
failed_downloads=()  # Array to store missing accessions

# Define log file path at the beginning
LOG_DIR=""
LOG_FILE=""

# Function to display usage
usage() {
    echo "Usage: $0 -a <accession_file> -d <directory>"
    echo "  -a, --accession    Path to the TSV file used as input for samba.sh"
    echo "  -d, --directory    Path to the directory used as output for samba.sh"
    exit 1
}


# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--accession)
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


# Validate inputs
if [[ -z "$ACCESSION_FILE" || -z "$DIRECTORY" ]]; then
    echo "Error: Both -a and -d are required."
    usage
fi

# Define log directory and file paths
LOG_DIR="${DIRECTORY}/logs"
LOG_FILE="${LOG_DIR}/failed_downloads.log"

# Check if the provided accession file exists
if [[ ! -f "$ACCESSION_FILE" ]]; then
    echo "Error: Accession file '$ACCESSION_FILE' not found."
    exit 1
fi

# Check if the provided directory exists
if [[ ! -d "$DIRECTORY" ]]; then
    echo "Error: Directory '$DIRECTORY' not found."
    exit 1
fi

# Process only .fastq.gz files in "${DIRECTORY}"/PRJ*/00.rawdata/
echo "[PROGRESS] -- Processing downloaded files in ${DIRECTORY} subfolders"

for file in "${DIRECTORY}"/PRJ*/00.rawdata/*.fastq.gz; do
    # Skip _2.fastq.gz files
    if [[ "$file" == *_2.fastq.gz ]]; then
        continue
    fi

    # If file does not have _1.fastq.gz on its name either, then it
    # is a SE sequencing file, so we add it to downloaded_accessions
    if [[ "$file" != *_1.fastq.gz ]]; then
        downloaded_accessions+=("$file")
        continue
    fi

    # If file is the forward pair of a PE sequence,
    # Construct the _2.fastq.gz filename
    paired_file="${file%_1.fastq.gz}_2.fastq.gz"

    # Check if both _1.fastq.gz and _2.fastq.gz exist
    if [[ -f "$file" && -f "$paired_file" ]]; then
        # Remove _1.fastq.gz and add to downloaded_accessions
        downloaded_accessions+=("${file%_1.fastq.gz}")
    else
        # Skip if either pair is missing (Force to download the pair again)
        continue
    fi
done

# Extract second column (accession) from TSV file and store in expected_accessions array
while IFS=$'\t' read -r bioproject accession _; do
    expected_accessions+=("$accession")
done < <(tail -n +2 "$ACCESSION_FILE")

# Check if expected accessions are present in downloaded accessions
for expected in "${expected_accessions[@]}"; do
    found=false

    for downloaded in "${downloaded_accessions[@]}"; do
        if [[ "$downloaded" == *"$expected"* ]]; then
            found=true
            break
        fi
    done

    if [[ "$found" == false ]]; then
        failed_downloads+=("$expected")
    fi
done

# Write missing accessions to log file if any are found
if [[ ${#failed_downloads[@]} -gt 0 ]]; then
    # Collapse failed_downloads into a | separated pattern
    pattern=$(IFS="|"; echo "${failed_downloads[*]}")

    # Extract full lines from ACCESSION_FILE where the missing accessions appear
    echo -e "study_accession\trun_accession" > "$LOG_FILE"
    grep -E "$pattern" "$ACCESSION_FILE" >> "$LOG_FILE"

else
    echo "All input accession numbers were successfully downloaded." > "$LOG_FILE"
fi

exit 0
