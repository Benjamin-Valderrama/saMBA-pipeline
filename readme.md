## saMBA-pipeline

This repository has the scripts used to build the **S**outh **A**merican **M**icro**B**iome **A**rchive (saMBA). Although this workflow was developed to generate an archive of faecal microbime samples from South Americans, the scripts can be used to create archives of other neglected populations, or to standardise the *in-bulnk* analysis of multiple 16s sequencing projects

## Preparation

Every software (and the specific versions) required for this analysis is detailed in `env/samba.yaml`. They can be easily installed using a software manager. We will use micromamba, but others 'flavors' of conda can be used if the code below is changed accordingly.

```
# make a local copy of this repository
git clone https://github.com/Benjamin-Valderrama/saMBA-pipeline

# build a local copy of the environment required for the analysis.
# NOTE: change 'micromamba' below if other sofware manager are used.
micromamba env create --name samba --file saMBA-pipeline/env/samba.yaml

# adding the folder `bin/` to path.
export PATH=$(pwd)/saMBA-pipeline/bin:$PATH

# give execute permissions to the main script.
chmod +x saMBA-pipeline/bin/samba.sh
```

## Usage

First, we will take a look at the help message of our main script `bin/saMBA.sh`
```
samba.sh --help
```

If the preparation steps were correctly followed, then you should see this:
```
    Usage: samba.sh -i accession_codes.tsv -o output --full --refdb path/to/database

    Required arguemnts:
      -i, --input          TSV file with two columns: project accessions and sample accessions from ENA.
      -o, --output         Path to folder where outputs will be saved.
    
    Workflow arguments:
      -f, --full           Run the full workflow with all the steps described below.
      -d, --download       Run data download [uses fastq-dl].
      -a, --analyse        Run reads quality check and alignment.
      -c, --consolidate    Join the outputs of all projects analysed.
    
    Database:
      -r, --refdb          [Required if --analyse is used] Path to the taxonomy reference database.
    
    Optional arguments:
      -h, --help           Display this help message.
```

Thus, saMBA.sh requires an input file and a path to a folder where the outputs will be direced. 
To illustrate how this workflow works, we added a small file in `demo/test.tsv` that can be used as input, and a small version of a reference database in `demo/reduced_silva.fa.gz`. 

Notice that you will need a full database for your own data. A popular option is [SILVA](https://www.arb-silva.de/), that can be downloaded from their website.

```
# the environment has to be activated before it can be used.
micromamba activate samba

# with the samba environment activated, run the main script in the background.
samba.sh -i saMBA-pipeline/demo/test.tsv -o archive -f -r path/to/database > progress.log &
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
