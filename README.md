# PSC-scDRS
PSC-scDRS is designed to link single-variant analysis scores with polygenic disease risk at single-cell RNA sequencing. It identifies cells with excess expression of disease-associated genes identified by Whole Exome Sequencing (WES).  

In the [Quick Start](#quick-start) section, you can follow the instructions to install the requirements and run simple samples.
To learn more about the functions, refer to the [Documentations](#documentations). Additionally, there, you can find detailed instructions on the data type and formats required as input for the PSC-scDRS function.
 
# Table of contents
- [Pipeline structure](#pipeline-structure)
- [Quick Start](#quick-start)
	- [Prerequisites and Configuration](#prerequisites-and-configuration)
    	- [Custom configuration](#custom-configuration)
	- [Installing dependencies](#installing-dependencies)
     - [Downloads](#downloads)
     - [Data](#data)
	 - [Running PSC-scDRS](#running-PSC-scDRS)
  
# Pipeline Structure
![Image Alt Text](https://github.com/ikmb/PSC-scDRS/blob/main/Images/Pipeline%20Structure.png)

# Quick Start
## Prerequisites and Configuration
PSC-scDRS requires significant computational resources. Ensure your system meets the following minimum requirements:

CPU: At least 16 cores.    
RAM: At least 32 GB (e.g., scDRS may require up to 360 GB).

Note: For large datasets, it is recommended to run the pipeline on a high-performance computing (HPC) system.

### Custom configuration
To fully utilize PSC-scDRS on an HPC or other systems, you must create a custom configuration file specifying:

Available CPU cores and memory.
Scheduler settings (e.g., local or SLURM).
Paths for reference databases.
Please refer to the installation and configuration documentation for more details.

## Downloads
### Clone PSC-scDRS  and install 
All the codes and needed files for the sample file will be downloaded in this step.

1. Make a folder where you want to keep data and files for the PSC-scDRS project.
For example, make a folder named PSC-scDRS in the home directory.
```bash
cd /home
mkdir -p PSC-scDRS
```
2. Clone the GitHub repo into that folder
```bash
cd /home/PSC-scDRS
git clone https://github.com/seirana/PSC-scDRS.git
```
3. If you get an error like “destination path 'PSC-scDRS' already exists”.
```bash
cd /home/PSC-scDRS
git pull --rebase origin main
```
## Installing dependencies
PSC-scDRS needs some extra software to run:
### step 1: Install scDRS
Pipeline will install it. If there is a problem, check [their page](https://pypi.org/project/scdrs/).
### step 2: Install the bcftools
Pipeline will install it. If there is a problem, check [here](https://samtools.github.io/bcftools/howtos/install.html).
### step 3: Install MAGMA
This installation must be done manually.

Select and install the correct version for your operating system and desired genome reference from [here](https://cncr.nl/research/magma/).

#### This command installs Python libraries, scDRS, and bcftools.
```bash
cd /home/PSC-scDRS
bash setup_dependencies.sh
```
## Data
Summary statistics of the GAISE single marker test on PSC whole-exome sequencing data are available as the sum_stat.zip file.
It includes 'CHR' as the chromosome number and 'POS' as the position on the chromosome. 'MarkerID' contains chromosome number:position: major allele: minor allele, Allele1 is the major allele, and 'Allele2' is the minor allele, and  'p.value' is the p-value from the SAGIE single marker test.

The single-cell RNA sequencing data from the healthy human liver from the study by Andrews, T.S. et al. (PMID: 38199298) is provided as a sample dataset after applying the required modifications by the scDRS (PMID: 36050550) method.

## Running PSC-scDRS
The pipeline will run the code smoothly.
```bash
cd /home/PSC-scDRS
bash PSC-scDRS_run.sh
```
