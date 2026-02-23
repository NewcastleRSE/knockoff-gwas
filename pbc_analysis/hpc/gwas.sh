#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=20GB
#SBATCH --output=slurm_gwas.out

# Load modules
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a

#Set dirs
source set_dirs.sh

date
echo "Running on $HOSTNAME GWAS with Plink"

# Run GWAS with Plink and Clumping
#./run_gwas.sh $DATA/Nicola
./run_summarise_gwas.sh $DATA/Nicola

echo "Node memory state: `free`"
date

