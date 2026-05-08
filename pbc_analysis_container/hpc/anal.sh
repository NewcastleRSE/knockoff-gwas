#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=100GB
# --time=14-00:00:00
#SBATCH --array=1-22                       # Run tasks for given chromosomes
#SBATCH --output=slurm_anal_%a.out

# Load modules
module load apptainer

# Set dirs
source ./set_dirs.sh

date
echo "Running on $HOSTNAME PBC analysis using container"

apptainer exec --bind $DATA:/data kogwas.sif run_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID /data/Nicola pbc 0.1 results


date
