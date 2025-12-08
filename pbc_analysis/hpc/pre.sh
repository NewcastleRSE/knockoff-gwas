#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=1
#SBATCH --time=120:00
#SBATCH --array=22                       # Tasks to run, corresponds to chromosome number
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
case "$SLURM_ARRAY_TASK_ID" in
    9|21)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 0.75 3
        ;;
    2)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 1.5 3
        ;;
    8|10|13,14)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 2.5 3
        ;;
    3)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 3.0 3
        ;;
    16|18)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 3.5 3
        ;;
    5)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 4.0 3
        ;;
    7|12|22)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 4.5 3
        ;;
    1|6|11|17|20)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 5.0 3
        ;;
    4)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 7.5 3
        ;;
    19)
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 10.0 3
        ;;
    *)
        # Try different window sizes for chromosomes here until a suitable size is found
        ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/Nicola pbc 0.1 results 12.0 3
        ;;
esac



echo "Node memory state: `free`"
date

