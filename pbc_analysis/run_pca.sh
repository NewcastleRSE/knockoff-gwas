#!/bin/bash

source ./set_dirs.sh

# Exit on error, undefined variable, or failed pipe
set -euo pipefail

############################
# Configuration
############################

PLINK="plink"
PLINK2="plink2"
PREFIX=$1"_chr"          # Prefix for chromosome files (e.g., XXX_chr1.bed)
OUT=$1"_pca"
MERGE_LIST="merge_list.txt"
TMP_DIR=$DATA"/tmp/pca"

############################
# Setup
############################

# Create temp directory
mkdir -p "$TMP_DIR"

# Cleanup function (runs on exit/error)
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
}

# Run cleanup on exit or interrupt
trap cleanup EXIT INT TERM

############################
# Prepare merge list
############################

echo "Preparing merge list..."

> "$TMP_DIR/$MERGE_LIST"

for i in $(seq 2 22); do
    echo "${PREFIX}${i}.bed ${PREFIX}${i}.bim ${PREFIX}${i}.fam" \
        >> "$TMP_DIR/$MERGE_LIST"
done

############################
# Merge chromosomes
############################

echo "Merging chromosomes..."

$PLINK \
  --bfile ${PREFIX}1 \
  --merge-list "$TMP_DIR/$MERGE_LIST" \
  --make-bed \
  --out "$TMP_DIR/OUT"

############################
# Optional QC (recommended)
# Uncomment if needed
############################

# echo "Running QC filtering..."
#
# $PLINK \
#   --bfile "$TMP_DIR/OUT" \
#   --maf 0.05 \
#   --geno 0.02 \
#   --hwe 1e-6 \
#   --make-bed \
#   --out "$TMP_DIR/OUT_qc"
#
# PCA_INPUT="$TMP_DIR/OUT_qc"

# If QC not used:
PCA_INPUT="$TMP_DIR/OUT"

############################
# Run PCA
############################

echo "Running PCA..."

#$PLINK \
#  --bfile "$PCA_INPUT" \
#  --pca 5 \
#  --out "${OUT}"

${PLINK2} --bfile "$PCA_INPUT" --pca 10 approx --out "${OUT}"

############################
# Finished
############################

echo "Done!"

echo "Final outputs:"
echo ""
echo "  PCA results:"
echo "    ${OUT}.eigenvec"
echo "    ${OUT}.eigenval"
