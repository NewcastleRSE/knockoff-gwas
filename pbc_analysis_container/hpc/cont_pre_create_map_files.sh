#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --output=slurm_pre_create_map_files.out

# Load modules
module load apptainer

#Set dirs
source set_dirs.sh

date
echo "Running on $HOSTNAME PBC pre-analysis creating map files using container"

apptainer exec --bind $DATA:/data kogwas.sif run_pre_create_map_files.sh 1 22 /data/Nicola results /data/genetic_maps/genetic_map_GRCh37

date
