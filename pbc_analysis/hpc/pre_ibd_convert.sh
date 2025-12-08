#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=1
#SBATCH --time=120:00
#SBATCH --array=1-22                       # Tasks to run, corresponds to chromosome number
#SBATCH --output=slurm_pre_ibd_%a.out

# Load modules

module load BCFtools/1.22-GCC-13.3.0
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a
module load plink/2.0.0

#Set dirs
source set_dirs_comet.sh

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing - converting RaPIDv1.7 to RaPISv1.2.3"

#cp $DATA/Nicola_ibd_chr$SLURM_ARRAY_TASK_ID.txt $DATA/Nicola_temp_ibd_chr$SLURM_ARRAY_TASK_ID.txt

Rscript ../new_knockoffgwas_pipeline/knockoffgwas_pipeline/new_bits/convert_ibd_format3.R  $DATA/Nicola_temp_ibd_chr$SLURM_ARRAY_TASK_ID.txt $DATA/Nicola_ibd_chr$SLURM_ARRAY_TASK_ID.txt
        
echo "Node memory state: `free`"
date

