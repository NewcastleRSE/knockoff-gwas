#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --array=1-22                       # Tasks to run, corresponds to chromosome number
#SBATCH --output=slurm_pre_%a.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a
module load plink/2.0.0

#Set dirs
source set_dirs.sh

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing"

# Phase chromosome data
../new_knockoffgwas_pipeline/run_pre_phasing.sh $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc results

# It may be necessary to change the segment length and window size until suitable IBD data is returned
../new_knockoffgwas_pipeline/run_pre_ibd.sh $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc results 25 3

echo "Node memory state: `free`"
date

