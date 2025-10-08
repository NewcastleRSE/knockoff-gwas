#!/bin/bash
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=4
#SBATCH --partition=highmem_paid
#SBATCH --time=48:00:00
#SBATCH --array=6-6                       # Run tasks 1 through 22
#SBATCH --output=slurm_pre_%a.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a 

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing"

../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID data/Nicola pbc 0.1 results

echo "Node memory state: `free`"
date
