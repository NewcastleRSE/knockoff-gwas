#!/bin/bash
#
# Compute the KnockoffGWAS test statistics
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
#      also path & file prefix (not including "_ibd_chrXX") for genetic map data, .txt
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
mkdir -p $TMP_DIR"/knockoffs_full"
mkdir -p $TMP_DIR"/stats"

# Storage of output files
OUT_DIR=$6
mkdir -p $OUT_DIR

# List of chromosomes
CHR_MIN=$1
CHR_MAX=$2
CHR_LIST=($(seq $CHR_MIN $CHR_MAX))

# List of resolutions
RESOLUTION_LIST=("6" "5" "4" "3" "2" "1" "0")

# Utility scripts
AUGMENT_GENOTYPES="$SCRIPTPATH/utils/merge_chromosomes.sh"
BED_TO_FBM="Rscript --vanilla $SCRIPTPATH/utils/make_FBM.R"
COMPUTE_STATS="Rscript --vanilla $SCRIPTPATH/utils/lasso.R"

# Which operations should we perform?
FLAG_MAKE_FBM=1
FLAG_COMPUTE_STATS=1

############
# Make FBM #
############

if [[ $FLAG_MAKE_FBM == 1 ]]; then
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Converting augmented genotypes into FBM"
  echo "----------------------------------------------------------------------------------------------------"

  for RESOLUTION in "${RESOLUTION_LIST[@]}"; do
    echo ""
    echo "Processing at resolution "$RESOLUTION" ..."
    echo ""

    # Basename for output FBM
    OUT_BASENAME=$TMP_DIR"/knockoffs_full/example_res"$RESOLUTION
    # Combine genotypes and knockoffs into bed
    $AUGMENT_GENOTYPES $OUT_BASENAME $RESOLUTION $CHR_MIN $CHR_MAX $TMP_DIR
    # Convert augmented BED to FBM
    $BED_TO_FBM $OUT_BASENAME $OUT_BASENAME
  done

else
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Skipping conversion of augmented genotypes into FBM"
  echo "----------------------------------------------------------------------------------------------------"
fi

###########################
# Compute test statistics #
###########################

if [[ $FLAG_COMPUTE_STATS == 1 ]]; then
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Computing test statistics"
  echo "----------------------------------------------------------------------------------------------------"

  for RESOLUTION in "${RESOLUTION_LIST[@]}"; do
    echo ""
    echo "Processing at resolution "$RESOLUTION" ..."
    echo ""

    # Augmented genotypes in FBM format
    DATA_BASENAME=$TMP_DIR"/knockoffs_full/example_res"$RESOLUTION
    # Phenotype file
    PHENO_FILE="$3_phenotypes.txt"
    # Phenotype name
    PHENO_NAME=$4
    # Output file
    OUT_BASENAME=$TMP_DIR"/stats/example_res"$RESOLUTION
    # Compute test statistics
    $COMPUTE_STATS $DATA_BASENAME $PHENO_FILE $PHENO_NAME $OUT_BASENAME

  done

else
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Skipping test statistics"
  echo "----------------------------------------------------------------------------------------------------"
fi
