#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --array=1-22                       # Tasks to run, corresponds to chromosome number
#SBATCH --output=slurm_pre_%a.out

# Load modules
module load apptainer

#Set dirs
source set_dirs.sh

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing using container"

# Phase chromosome data
apptainer exec --bind $DATA:/data kogwas.sif run_pre_phasing.sh $SLURM_ARRAY_TASK_ID /data/Nicola pbc results

# It may be necessary to change the segment length and window size until suitable IBD data is returned
apptainer exec --bind $DATA:/data kogwas.sif run_pre_ibd.sh $SLURM_ARRAY_TASK_ID /data/Nicola pbc results 25 3

date

