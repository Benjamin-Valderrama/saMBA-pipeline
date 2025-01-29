#!/bin/bash

# Workflow arguments: Default values
study_folder=""
accession_number=""

run_all=false
run_download=false
run_dada2=false


# Set path to folder with the scripts used in saMBA
SCRIPTS_FOLDER="$(dirname "$(realpath "$0")")" # Folder with all scripts
ANALYSIS_SCRIPTS="${SCRIPTS_FOLDER}/analysis" # Folder with scripts used in the analysis of one project


# Function to display script usage
function display_usage() {
    echo ""
    echo "Usage: $0 -s|--study_folder STUDY_FOLDER [-a|--accession_number ACCESSION_NUMBER] [-r|--run_all]"
    echo "	[--run_download] [--dada2] [-h|--help]"
    echo ""
    echo "Optional arguments:"
    echo "  -h, --help               Display this help message."
    echo ""
    echo "Required arguemnts:"
    echo "  -s, --study_folder       Specify the name for the study included in this meta-analysis. (Required)"
    echo "  -a, --accession_number   Specify the accession number of the raw data at the ENA (Only used if --run_all or --run_download are provided)."
    echo ""
    echo "Workflow arguments:"
    echo "  -r, --run_all            Run all steps of the workflow."
    echo "  --run_download           Run data download [uses fastq-dl]."
    echo "  --run_dada2              Run reads quality check and alignment [uses DADA2 in R]."
    echo ""
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -s|--study_folder)
            study_folder="$2"
            shift
            shift
            ;;
        -r|--run_all)
            run_all=true
            shift
            ;;
        -a|--accession_number)
            accession_number="$2"
            shift
            shift
            ;;
        --run_download)
            run_download=true
            shift
            ;;
        --run_dada2)
            run_dada2=true
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


# 1. dada2: preparing count table of taxas.
if [ "$run_all" = true ] || [ "$run_dada2" = true ]; then
    mkdir ${study_folder}/01.dada2

    library_layout=$(bash ${ANALYSIS_SCRIPTS}/library_layout.sh ${study_folder})
    echo "PROGRESS -- Detected library layout : $library_layout"

    if [ "$library_layout" = paired_end ]; then
        # run dada2 in pair end mode
        echo "PROGRESS -- Performing paired end taxonomic profiling with DADA2."
        Rscript ${ANALYSIS_SCRIPTS}/PE_dada2.R ${study_folder} > ${study_folder}/nohups/dada2.log

    elif [ "$library_layout" = single_end ]; then
        # run dada2 in single end mode
        echo "PROGRESS -- Performing single end taxonomic profiling with DADA2."
        Rscript ${ANALYSIS_SCRIPTS}/SE_dada2.R ${study_folder} > ${study_folder}/nohups/dada2.log

    else
	echo "[ERROR] -- Library layout undetermined. Project can't be included."
	exit 1
    fi
fi


# 3. Check the quality of the project. Re run paired end projects as single end if required.
quality_check=$( Rscript ${ANALYSIS_SCRIPTS}/quality_check_dada2.R ${study_folder} ${library_layout})
echo "PROGRESS -- Quality check : ${quality_check}"

# If quality check was an empty string
if [[ -z $quality_check ]]; then
    echo "[ERROR] -- Quality check: undetermined."
    echo "[ERROR] -- Forcing the end of the analysis."
    exit 1


# If library layout was paired end and quality_check is not passed (i.e., fails in any check)...
elif [[ $library_layout == "paired_end" ]] && [[ $quality_check != "PASSED" ]]; then

    # We run DADA2 for the second time as if the library layout were single end
    library_layout="single_end"

    echo "PROGRESS -- Re-analysing project as : ${library_layout}"
    Rscript ${ANALYSIS_SCRIPTS}/SE_dada2.R ${study_folder} > ${study_folder}/nohups/dada2.log

    # Check the results of the single end re run
    quality_check_rerun=$( Rscript ${ANALYSIS_SCRIPTS}/quality_check_dada2.R ${study_folder} ${library_layout})
    echo "PROGRESS -- Quality check after re-analysis: ${quality_check_rerun}"

    # If failed for a second time...
    if [[ $quality_check_rerun != "PASSED" ]]; then
    echo "[ERROR] -- Quality check: FAILED."
    echo "[ERROR] -- Project can't be included."
    exit 1
    fi


# If library layout was single end and quality_check is not passed (i.e., fails in any check)...
elif [[ $library_layout == "single_end" ]] && [[ $quality_check != "PASSED"  ]]; then
    echo "PROGRESS -- Quality check: FAILED."
    echo "[ERROR] -- Project can't be included."
    exit 1
fi


# 4. If project can be included, remove samples with low quality and keep the rest...
if [[ $quality_check == "PASSED" ]] || [[ $quality_check_rerun == "PASSED" ]]; then
    echo "PROGRESS -- Removing samples with low quality from project."
    Rscript ${ANALYSIS_SCRIPTS}/filter_samples.R ${study_folder} ${library_layout} > ${study_folder}/nohups/filter_samples.log
fi


# 5. Collapse count table from ASVs to genus (keep both as outputs)
if [[ $quality_check == "PASSED" ]] || [[ $quality_check_rerun == "PASSED" ]]; then
    echo "PROGRESS -- Collapsing ASVs from clean count table to genus"
    Rscript ${ANALYSIS_SCRIPTS}/collapse_asv_to_genus.R ${study_folder} > ${study_folder}/nohups/collapse_count_table.log

   echo "PROGRESS -- ${study_folder} successfully analysed"
fi
