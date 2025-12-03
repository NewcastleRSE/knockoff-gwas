#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH --time=120:00
#SBATCH --array=2,3,8,9,10,13,14,21                       # Run tasks 1 through 22
#SBATCH --output=slurm_pre_%a.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a

#Set dirs
source set_dirs_comet.sh

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing"

../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 3 3

echo "Node memory state: `free`"
date

