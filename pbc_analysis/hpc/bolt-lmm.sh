#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=10GB
#SBATCH --output=slurm_bolt_lmm_%a.out

MIN_CHR=1
MAX_CHR=22

# Load modules
module load BOLT-LMM
module load PLINK/1.9b_6.21-x86_64
module load R/4.5.1-gfbf-2024a 

# Set dirs
source ./set_dirs.sh

date
echo "Running on $HOSTNAME PBC analysis"

../new_knockoffgwas_pipeline/run_lmm.sh ${MIN_CHR} ${MAX_CHR} $DATA/Nicola pbc 0.1 results $DATA"/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz" $DATA"/tables/genetic_map_hg19_withX.txt.gz"

date
