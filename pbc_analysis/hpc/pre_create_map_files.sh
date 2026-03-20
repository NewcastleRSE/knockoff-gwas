#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --output=slurm_pre_%a.out

# Load modules


module load R/4.5.1-gfbf-2024a


# MAP_FILE="../../genetic_maps/genetic_map_GRCh37_chr${CHR}.txt"
# ../../genetic_maps/genetic_map_GRCh37

#Set dirs
source set_dirs.sh

date
echo "Running on $HOSTNAME PBC pre-analysis data preparing"

../new_knockoffgwas_pipeline/run_pre_create_map_files.sh 1 22 $DATA/Nicola pbc 0.1 results $DATA/genetic_maps/genetic_map_GRCh37


date

