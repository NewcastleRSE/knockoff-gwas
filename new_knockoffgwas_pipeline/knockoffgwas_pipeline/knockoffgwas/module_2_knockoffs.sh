#!/bin/bash
#
# Generate knockoff negative-controls
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
#      also path & file prefix (not including "_ibd_chrXX") for ibd data, .txt
# $4 = phenotype name
# $5 = FDR rate
# $6 = output folder

# If haplotype data exists, .bgen, .sample then it is used 
# If IBD data exists, .txt, then it is used
# Otherwise it is calculated the run_pre_knockoff_gwas.sh script should be ran

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Temporary folder for temporary files
TMP_DIR=$6"/tmp"
mkdir -p $TMP_DIR
mkdir -p $TMP_DIR"/knockoffs"

# Storage of output files
OUT_DIR=$6
mkdir -p $OUT_DIR

# List of chromosomes
CHR_MIN=$1
CHR_MAX=$2

# Path to snpknock2 executable built as described above
SNPKNOCK2="$SCRIPTPATH/../snpknock2/bin/snpknock2"

# Which operations should we perform?
FLAG_GENERATE_KNOCKOFFS=1

######################
# Generate knockoffs #
######################

if [[ $FLAG_GENERATE_KNOCKOFFS == 1 ]]; then
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Generating knockoffs"
  echo "----------------------------------------------------------------------------------------------------"

  # Run snpknock2
  $SNPKNOCK2 \
    --bgen "$3_chr{"$CHR_MIN":"$CHR_MAX"}" \
    --keep "$3_qc_samples.txt" \
    --extract "$3_qc_chr{"$CHR_MIN":"$CHR_MAX"}.txt" \
    --map "$3_map_chr{"$CHR_MIN":"$CHR_MAX"}.txt" \
    --part "$TMP_DIR/partitions/example_chr{"$CHR_MIN":"$CHR_MAX"}.txt" \
    --ibd "$3_ibd_chr{"$CHR_MIN":"$CHR_MAX"}.txt" \
    --K 10 \
    --cluster_size_min 1000 \
    --cluster_size_max 10000 \
    --hmm-rho 1 \
    --hmm-lambda 1e-3 \
    --windows 0 \
    --n_threads 4 \
    --seed 2020 \
    --compute-references \
    --generate-knockoffs \
    --out $TMP_DIR"/knockoffs/knockoffs_chr{"$CHR_MIN":"$CHR_MAX"}"

else
  echo ""
  echo "----------------------------------------------------------------------------------------------------"
  echo "Skipping generation of knockoffs"
  echo "----------------------------------------------------------------------------------------------------"
fi
