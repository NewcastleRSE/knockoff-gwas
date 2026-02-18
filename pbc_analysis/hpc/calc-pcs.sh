#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --output=slurm_calc_pcs.out

# Load modules
module load PLINK/1.9b_6.21-x86_64
module load plink/2.0.0

#Set dirs
source set_dirs.sh

date
echo "Running on $HOSTNAME principle component calculation"

# Run different chromosomes with different window sizes to get reasonable number of IBDs returned

# Try different window sizes for chromosomes here until a suitable size is found
./run_pca.sh $DATA/Nicola

echo "Node memory state: `free`"
date

