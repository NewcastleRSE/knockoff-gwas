#!/bin/bash
#
# Partition the variants through adjacent clustering
#
# Authors: Matteo Sesia
# Date:    07/21/2020

set -e

# Any subsequent(*) commands which fail will cause the shell script to exit immediately

# Modified by Richard Howey for general use
# March 2025

# Parameters
#
# $1 = start chr number
# $2 = end chr number
# $3 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam
#      also path & file prefix (not including "_map_chrXX") for genetic map data, .txt
#      also path & file prefix (not including "_ibd_chrXX") for ibd map data, .txt
# $4 = phenotype name
# $5 = FDR rate
# $6 = output folder

# If haplotype data exists, .bgen, .sample then it is used otherwise it is calculated
# If IBD data exists, .txt, then it is used otherwise it is calculated

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Set dirs
source ./set_dirs.sh

# Temporary folder for temporary files
TMP_DIR=$DATA"/tmp"
mkdir -p $TMP_DIR
mkdir -p $TMP_DIR"/partitions"

# List of chromosomes
CHR_LIST=$(seq $1 $2)

# List of resolutions in cM (note: this is also fixed inside the R script)
RESOLUTION_LIST=("0" "0.01" "0.05" "0.1" "0.2" "0.5" "1")

# Utility scripts
PARTITION_VARIANTS="Rscript --vanilla $SCRIPTPATH/utils/partition.R"

# Which operations should we perform?
FLAG_PARTITION=1

################
# Partitioning #
################

if [[ $FLAG_PARTITION == 1 ]]; then
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Partitioning variants"
  echo "----------------------------------------------------------------------------------------------------"

  for CHR in $CHR_LIST; do

    echo ""
    echo "Processing chromosome "$CHR" ..."
    echo ""

    # Input genotype files (PLINK format)
    GENO_BIM="$3_chr"$CHR".bim"

    # List of variants that passed QC
    QC_VARIANTS="$3_qc_chr"$CHR".txt"

    # Genetic map file
    GEN_MAP="$3_map_chr"$CHR".txt"

    # Basename for output dendrogram file
    OUT_FILE=$TMP_DIR"/partitions/chr"$CHR".txt"

    # Partition the variants at different resolutions
    $PARTITION_VARIANTS $GEN_MAP $GENO_BIM $QC_VARIANTS $OUT_FILE
  done

else
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Skipping variant partitioning"
  echo "----------------------------------------------------------------------------------------------------"
fi
