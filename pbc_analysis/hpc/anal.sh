#!/bin/bash
#SBATCH --partition=long_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --array=22                       # Run tasks for given chromosomes
#SBATCH --output=slurm_anal_%a.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a 

# Set dirs
source ./set_dirs.sh

date
echo "Running on $HOSTNAME PBC analysis"

../new_knockoffgwas_pipeline/run_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results

date
