#!/bin/bash
#SBATCH --partition=default_free
#SBATCH --account=kogwas
#SBATCH --cpus-per-task=1
#SBATCH --mem=10GB
#SBATCH --output=cont_bolt_lmm_%a.out

# Set dirs
source ./set_dirs.sh

date
echo "Running on $HOSTNAME PBC BOLT-LMM analysis using container"

apptainer exec --bind $DATA:/data kogwas.sif run_lmm.sh 1 22 /data/Nicola pbc results /data/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz /data/tables/genetic_map_hg19_withX.txt.gz

date
