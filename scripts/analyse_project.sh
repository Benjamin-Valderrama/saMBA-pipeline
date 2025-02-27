#!/bin/bash

# This script was recycled, so although it can be used to download data, that option is not used here

# Required arguments: Default values
study_folder=""
refdb=""

# Workflow arguments: Default values
run_all=false
run_dada2=false

# Set path to folder with the scripts used in saMBA
SCRIPTS_FOLDER="$(dirname "$(realpath "$0")")" # Folder with all scripts
ANALYSIS_SCRIPTS="${SCRIPTS_FOLDER}/analysis" # Folder with scripts used in the analysis of one project


# Function to display script usage
function display_usage() {
    echo ""
    echo "Usage: $0 -s|--study_folder STUDY_FOLDER [-r|--run_all] [--refdb path/to/database]"
    echo ""
    echo "Required arguemnts:"
    echo "  -s, --study_folder       Specify the name for the study included in this meta-analysis. (Required)"
    echo "  --refdb                  Path to the taxonomy reference database"
    echo ""
    echo "Workflow arguments:"
    echo "  -r, --run_all            Run all steps of the workflow."
    echo "  --run_dada2              Run reads quality check and alignment [uses DADA2 in R]."
    echo ""
    echo "Optional arguments:"
    echo "  -h, --help               Display this help message."
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
        --refdb)
            refdb="$2"
            shift
            shift
            ;;
        -r|--run_all)
            run_all=true
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
        Rscript ${ANALYSIS_SCRIPTS}/PE_dada2.R ${study_folder} ${refdb} > ${study_folder}/logs/dada2.log 2>&1

    elif [ "$library_layout" = single_end ] || [ "$library_layout" = forced_single_end ] ; then
        # run dada2 in single end mode
        echo "PROGRESS -- Performing single end taxonomic profiling with DADA2."
        Rscript ${ANALYSIS_SCRIPTS}/SE_dada2.R ${study_folder} ${refdb} > ${study_folder}/logs/dada2.log 2>&1

    else
	echo "[ERROR] -- Library layout undetermined. Project can't be included."
	exit 1
    fi
fi


# 2. Check the quality of the project. Re run paired end projects as single end if required.
quality_check=$( Rscript ${ANALYSIS_SCRIPTS}/project_quality_check_dada2.R ${study_folder} ${library_layout})
echo "PROGRESS -- Quality check : ${quality_check}"

# If quality check was an empty string
if [[ -z $quality_check ]]; then
    echo "[ERROR] -- Quality check: undetermined."
    echo "[ERROR] -- Forcing the end of the analysis."
    exit 1

# If library layout was single end (or forced_single_end) and quality_check failed ...
# discard the project
elif [[ "$library_layout" =~ single_end$  && $quality_check = *FAILED* ]]; then
    echo "PROGRESS -- Quality check: FAILED."
    echo "[ERROR] -- Project can't be included."
    exit 1
fi

# If library layout was paired end and quality_check contains 'FAILED' (i.e., fails any check)...
# rerun the analysis as single end
elif [[ $library_layout == "paired_end" && $quality_check = *FAILED* ]]; then

    # We run DADA2 for the second time as if the library layout was single end
    library_layout="single_end"

    echo "PROGRESS -- Re-analysing project as : ${library_layout}"
    Rscript ${ANALYSIS_SCRIPTS}/SE_dada2.R ${study_folder} ${refdb} > ${study_folder}/logs/dada2.log 2>&1

    # Run quality check for the single end re analysis
    quality_check_rerun=$( Rscript ${ANALYSIS_SCRIPTS}/project_quality_check_dada2.R ${study_folder} ${library_layout})
    echo "PROGRESS -- Quality check after re-analysis: ${quality_check_rerun}"


    # Discard project if re analysis failed
    if [[ $quality_check_rerun = *FAILED* ]]; then
	echo "[ERROR] -- Quality check: FAILED."
	echo "[ERROR] -- Project can't be included."
	exit 1
    # or if the quality check of the re run is empty
    elif [[ -z $quality_check_rerun ]]; then
        echo "[ERROR] -- Quality check: undetermined."
        echo "[ERROR] -- Forcing the end of the analysis."
        exit 1
    fi

# 3. If QC is successful, project can be included:
# copy ASV count table to 'outputs' folder, then collapse into genus-level count table (keep both as outputs)
if [[ $quality_check == "PASSED" ]] || [[ $quality_check_rerun == "PASSED" ]]; then
    echo "PROGRESS -- Collapsing ASVs from clean count table to genus"

    # make a copy of the ASV count table and fasta file into the outputs folder
    if [[ $library_layout == "paired_end" ]]; then
        cp ${study_folder}/01.dada2/ASV_count_table.tsv ${study_folder}/outputs/ASV_count_table.tsv
	cp ${study_folder}/01.dada2/ASVs.fa ${study_folder}/outputs/ASVs.fa

    elif [[ "$library_layout" =~ single_end$ ]]; then
	cp ${study_folder}/01.dada2/SE_ASV_count_table.tsv ${study_folder}/outputs/ASV_count_table.tsv
        cp ${study_folder}/01.dada2/SE_ASVs.fa ${study_folder}/outputs/ASVs.fa
    fi

    # collapse count table at ASV-level to genus-level
    Rscript ${ANALYSIS_SCRIPTS}/collapse_asv_to_genus.R ${study_folder} > ${study_folder}/logs/collapse_count_table.log 2>&1

   echo "PROGRESS -- ${study_folder} successfully analysed"
fi
