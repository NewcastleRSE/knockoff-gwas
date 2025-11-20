#!/bin/bash
#
# Threshold the the KnockoffGWAS test statistics with the knockoff filter
# and report discoveries
#
# Authors: Matteo Sesia
# Date:    07/19/2018

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

# Storage of output files
OUT_DIR=$6
mkdir -p $OUT_DIR

# List of chromosomes
CHR_LIST=($(seq $1 $2))

# List of resolutions
RESOLUTION_LIST=("6" "5" "4" "3" "2" "1" "0")

# Nominal FDR level (use 0.1 for 10%)
FDR=$5

# Utility scripts
FILTER_STATS="Rscript --vanilla $SCRIPTPATH/utils/filter_stats.R"

# Which operations should we perform?
FLAG_FILTER=1

#################################
# Filter the test statistics    #
#################################

if [[ $FLAG_FILTER == 1 ]]; then
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Filtering the test statistics"
  echo "----------------------------------------------------------------------------------------------------"

  for RESOLUTION in "${RESOLUTION_LIST[@]}"; do
    echo ""
    echo "Processing at resolution "$RESOLUTION" ..."
    echo ""

    # Stats basename
    STATS_BASENAME=$TMP_DIR"/stats/example_res"$RESOLUTION

    # Partition file
    DATA_BASENAME=$TMP_DIR"/knockoffs_full/example_res"$RESOLUTION

    # Basename for output files
    OUT_BASENAME=$OUT_DIR"/example_res"$RESOLUTION

    # Threshold the test statistics and report discoveries
    $FILTER_STATS $STATS_BASENAME $DATA_BASENAME $FDR $OUT_BASENAME

  done

else
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Skipping filtering of the test statistics"
  echo "----------------------------------------------------------------------------------------------------"
fi
