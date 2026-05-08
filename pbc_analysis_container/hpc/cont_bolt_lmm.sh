#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=comet_kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=10GB
#SBATCH --output=slurm_bolt_lmm.out

module load apptainer

# Set dirs
source ./set_dirs.sh

date
echo "Running on $HOSTNAME PBC BOLT-LMM analysis using container"

apptainer exec --bind $DATA:/data kogwas.sif run_lmm.sh 1 22 /data/Nicola pbc lmm_results /data/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz /data/tables/genetic_map_hg19_withX.txt.gz

date
