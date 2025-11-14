#!/bin/bash
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=1
#SBATCH --partition=highmem_paid
#SBATCH --time=00:05                    
#SBATCH --output=slurm_test_dir.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing"

#../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID data/Nicola pbc 0.1 results

source set_dirs_comet.sh

echo Data dir is $DATA
echo IBD dir is $IBD_DATA

echo "Node memory state: `free`"
date

