#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --array=1-14,16-20                       # Tasks to run, corresponds to chromosome number
#SBATCH --output=slurm_pre_%a.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a
module load plink/2.0.0

#Set dirs
source set_dirs_comet.sh

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing"

# Run different chromosomes with different window sizes to get reasonable number of IBDs returned

# Try different window sizes for chromosomes here until a suitable size is found
../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 10 3

echo "Node memory state: `free`"
date

