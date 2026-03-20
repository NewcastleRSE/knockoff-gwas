#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=100GB
# --time=14-00:00:00
#SBATCH --array=1-22                       # Run tasks for given chromosomes
#SBATCH --output=slurm_anal_%a_FDR20.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a 

# Set dirs
source ./set_dirs.sh

date
echo "Running on $HOSTNAME PBC analysis"

../new_knockoffgwas_pipeline/run_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.2 results_d25_w3_FDR20

date
