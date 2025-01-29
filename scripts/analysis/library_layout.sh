#!/bin/bash

bioproject=$1

# number of files downloaded
files_downloaded=$(ls $bioproject/00.rawdata/*.fastq.gz | wc -l)

# if ls gives error, it is redirected to the library_layout.out file.
# ls will give error if there are no _1 and _2 files (i.e., when the project is single_end)
num_forward_files=$(ls $bioproject/00.rawdata/*_1.fastq.gz 2>> $bioproject/nohups/lib_layout.out | wc -l)
num_reverse_files=$(ls $bioproject/00.rawdata/*_2.fastq.gz 2>> $bioproject/nohups/lib_layout.out | wc -l)


# If there is at least one file downloaded...
if [[ $files_downloaded -gt 0 ]]; then

	# if files don't have either _1 or _2 in their names
	if [[ $num_forward_files -eq 0 ]] && [[ $num_reverse_files -eq 0 ]]; then
		echo "single_end"

	# if number of forward files matches the number of reverse files
	elif [[ $num_forward_files -eq $num_reverse_files ]]; then
		echo "paired_end"

	# if the numbers of forward and reverse files doesn't match,
	# library layout is forced to be single end
	elif [[ $num_forward_files -ne $num_reverse_files ]]; then
                rm $project_folder/00.rawdata/*_2.fastq.gz
        	echo "forced_single_end"
	fi

else
	echo "[ERROR] -- FAILED TO DOWNLOAD"
fi
