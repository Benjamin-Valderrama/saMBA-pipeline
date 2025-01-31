#!/bin/bash

# Workflow arguments: Default values
full=""
download=""
analyse=""
consolidate=""

# Path to reference db: Default
refdb=""

# Set path to folder with the scripts used in saMBA
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
saMBA_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPTS_FOLDER="$saMBA_ROOT/scripts"

function display_usage() {
    echo "Usage: $0 -i accession_codes.tsv -o output"
    echo "      [-d|--download] [-a|--analyse] [-r|--refdb] [-h|--help]"
    echo ""
    echo "Required arguemnts:"
    echo "  -i, --input          TSV file with two columns: project accessions and sample accessions from ENA."
    echo "  -o, --output         Path to folder where outputs will be saved."
    echo ""
    echo "Workflow arguments:"
    echo "  -f, --full           Run the full workflow with all the steps described below"
    echo "  -d, --download       Run data download [uses fastq-dl]."
    echo "  -a, --analyse        Run reads quality check and alignment."
    echo "  -c, --consolidate    Join the outputs of all projects analysed"
    echo ""
    echo "Database:"
    echo "  -r, --refdb          [Required if --analyse is used] Path to the taxonomy reference database"
    echo ""
    echo "Optional arguments:"
    echo "  -h, --help           Display this help message."
    echo ""
    exit 1
}

# Display usage if no required arguments were provided
if [[ $# -eq 0 ]]; then
    display_usage
fi


# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -i|--input)
            input="$2"
            shift
            shift
            ;;
        -o|--output)
            output="$2"
            shift
            shift
            ;;
        -f|--full)
            full=true
            shift
            ;;
        -d|--download)
            download=true
            shift
            ;;
        -a|--analyse)
            analyse=true
            shift
            ;;
        -c|--consolidate)
            consolidate=true
            shift
            ;;
        -r|--refdb)
            refdb="$2"
            shift
            shift
            ;;
        -h|--help)
            display_usage
            ;;
        *)
	    echo "Unknown option: $1"
            display_usage
            ;;
    esac
done


# Step 1 -- Preparation
# check that reference database exists
if [ ! -f "$refdb" ]; then
    echo "[ERROR] -- $refdb doesn't exists"
    exit 1
fi

if [ "$full" = true ] || [ "$download" = true ] || [ "$analyse" = true ]; then
    # create a folder for log files
    mkdir -p "${output}/nohups"
fi


# Step 2 -- Data download:
if [ "$full" = true ] || [ "$download" = true ]; then

    # counter of analysed projects
    n=0

    # read the file line by line, skipping the header
    tail -n +2 "${input}" | while IFS=$'\t' read -r bioproject run_accession; do

        # if it is a new bioproject...
        if [ ! -d $output/$bioproject ]; then

            # keep track of analysed projects
            ((n++))

            # create a directory for the bioproject if it doesn't already exist
            mkdir -p "$output/$bioproject/00.rawdata"
            mkdir -p "$output/$bioproject/nohups"
            mkdir -p "$output/$bioproject/outputs"

       fi

        # download data
        echo "PROGRESS -- Downloading raw data of project $n: ${bioproject}" > ${output}/nohups/${bioproject}.log
        echo "Downloading : $run_accession" >> $output/$bioproject/nohups/download.log

        fastq-dl --accession $run_accession --outdir $output/$bioproject/00.rawdata --silent

        # download one file at a time:

        # Comment: I want the script to behave differently but I don't know how to do it:
        # I want all the run accessions of the same project to be downloaded at once, and
        # all files of the same project have to be downloaded before starting the download
        # of samples in a new project.

        last_pid=$!
        wait $last_pid

    done
fi

# Step 3 -- Data analysis of each project
if [ "$full" = true ] || [ "$analyse" = true ]; then

    # counter of analysed projects
    n=0

    # analyse the downloaded data
    cut -f1 $input | tail -n +2 | uniq | while read -r bioproject; do

        ((n++))
        echo "PROGRESS -- Analysing project $n: ${bioproject}" >> ${output}/nohups/${bioproject}.log

        # Download ENA metada for the bioproject
        fastq-dl --accession $bioproject --outdir "$output/$bioproject/00.rawdata" --only-download-metadata --silent


        # launch the analysis of the projects
        # while overall progress of the analysis goes to ${output}/nohups/${bioproject}.out,
        # step-specific logs can be found in ${output}/${bioproject}/nohups/
        bash ${SCRIPTS_FOLDER}/analyse_project.sh -s ${output}/${bioproject} --run_dada2 --db $refdb >> ${output}/nohups/${bioproject}.log &

        # save the PID of the process and add that to the log file to keep track of the analysis steps
        last_pid=$!
        wait "$last_pid"

        echo "Project ${accession_number} (number $n) finished\n"

    done
fi

# Step 4 -- Project integration
if [ "$full" = true ] || [ "$consolidate" = true ];
    # one .out file is generated for each step of the following script
    bash ${SCRIPTS_FOLDER}/consolidate_projects.sh $output
fi

#micromamba deactivate

