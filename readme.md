## saMBA-pipeline

This repository has the scripts used to build the **S**outh **A**merican **M**icro**B**iome **A**rchive (saMBA). Although this workflow was developed to generate an archive of faecal microbime samples from South Americans, the scripts can be used to create archives of other neglected populations, or to standardise the *in-bulnk* analysis of multiple 16s sequencing projects

## Preparation

Every software required for this analysis is detailed in `env/samba.yaml`. Each software (with required versions) can be easily installed using a software manager like micromamba.

```
# make a local copy of this repository
git clone https://github.com/Benjamin-Valderrama/saMBA-pipeline

# build an exact local copy of the environment required for this analysis
# substitute 'micromamba' below with the name of the sofware manager you use, if needed
micromamba env create --name samba --file saMBA-pipeline/env/samba.yaml

# adding the folder `bin/` to path
export PATH=$(pwd)/saMBA-pipeline/bin:$PATH

# give execute permissions to the main script
chmod +x saMBA-pipeline/bin/saMBA.sh
```

## Usage

First, we can take a look at the help message of our main script `bin/saMBA.sh`
```
saMBA.sh --help
```

Which should print the following message
```
    Usage: $0 -i accession_codes.tsv -o output_samba/
          [-d|--download] [-a | --analyse] [-h|--help]
    
    Required arguemnts:
      -i, --input          TSV file with two columns: project accessions and sample accessions from ENA.
      -o, --output         Path to folder where outputs will be saved.

    Workflow arguments:
      -d, --download       Run data download [uses fastq-dl].
      -a, --analyse        Run reads quality check and alignment [uses kneaddata].
    
    Optional arguments:
      -h, --help           Display this help message.
```

Thus, saMBA.sh requires an input file and a path to a folder where the outputs will be direced. In this repository, we have added a the `examples/test.tsv` file as a demo to show how users how to work with this pipeline

```
# the environment has to be activated before it can be used
micromamba activate samba

# with the samba environment activated, run the main script in the background
saMBA.sh -i saMBA-pipeline/examples/test.tsv -o archive > progress.log &
```

## Output description

Add details here...

## How to cite this work

Add DOI of the preprint...

## Future plans for the repository/workflow (Contributions are wellcomed)

* To build a setup.sh script that makes the installation of this pipeline even easier for end-users.
* To add the option the option to run PICRUSt2 for each project analysed
* To add a feature that allows user to set all key arguments of DADA2 and PICRUSt2 through a file of arguemnts
* Move it to a Snakemake workflow
