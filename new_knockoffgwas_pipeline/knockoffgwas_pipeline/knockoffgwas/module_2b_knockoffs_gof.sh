#!/bin/bash
#
# Evaluate knockoff goodness of fit
#
# Authors: Matteo Sesia
# Date:    07/27/2021

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
mkdir -p $TMP_DIR"/knockoffs"
mkdir -p $6"/knockoffs_gof"
mkdir -p $6"/knockoffs_gof_plots"

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
PLOT_GOF="Rscript --vanilla $SCRIPTPATH/utils/knockoffs_gof.R"

# Which operations should we perform?
FLAG_GOF_KNOCKOFFS=1

##########################
# Evaluate Knockoffs GOF #
##########################

if [[ $FLAG_GOF_KNOCKOFFS == 1 ]]; then
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Checking knockoffs goodness-of-fit"
  echo "----------------------------------------------------------------------------------------------------"

  for RESOLUTION in "${RESOLUTION_LIST[@]}"; do
    for CHR in "${CHR_LIST[@]}"; do
    echo ""
    echo "Computing goodness-of-fit diagnostics for chromosome "$CHR" at resolution "$RESOLUTION" ..."
    echo ""

    STATS_BASENAME=$6"/knockoffs_gof/knockoffs_chr"$CHR"_res"$RESOLUTION
    GROUPS_FILE=$TMP_DIR"/knockoffs/knockoffs_chr"$CHR"_res"$RESOLUTION"_grp.txt"
    OUT_BASENAME=$6"/knockoffs_gof_plots/knockoffs_chr"$CHR"_res"$RESOLUTION

    # Compute self-similarity diagnostics
    plink --bfile $TMP_DIR"/knockoffs/knockoffs_chr"$CHR"_res"$RESOLUTION \
          --keep-allele-order \
          --freq \
          --r in-phase --ld-window 2 --ld-window-kb 0 \
          --memory 9000 \
          --out $STATS_BASENAME"_self"

    # Compute exchangeability diagnostics
    plink --bfile $TMP_DIR"/knockoffs/knockoffs_chr"$CHR"_res"$RESOLUTION \
          --keep-allele-order \
          --r2 in-phase --ld-window 5000 --ld-window-kb 10000 --ld-window-r2 0.01 \
          --memory 9000 \
          --out $STATS_BASENAME

    # Make GOF plots
    $PLOT_GOF $CHR $RESOLUTION $STATS_BASENAME $GROUPS_FILE $OUT_BASENAME
    done
  done

else
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Skipping knockoffs goodness-of-fit"
  echo "----------------------------------------------------------------------------------------------------"
fi
