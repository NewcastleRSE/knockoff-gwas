#!/bin/bash

source set_dirs.sh

# Exit on error
set -euo pipefail

############################
# Configuration
############################

PLINK="plink"

# Chromosome file prefix
PREFIX=$1"_chr"

# PCA eigenvec file
EIGENVEC=$1"_pca.eigenvec"

# Output directory
OUTDIR="results_gwas"


# Temp directory
TMP_DIR=$DATA"/tmp/tmp_gwas"

# GWAS type: linear or logistic
# GWAS_TYPE="linear"
GWAS_TYPE="logistic"

# Clumping parameters (standard GWAS defaults)
CLUMP_P1=5e-8
CLUMP_P2=1e-2
CLUMP_R2=0.1
CLUMP_KB=250

############################
# Setup
############################

mkdir -p "$OUTDIR"
mkdir -p "$TMP_DIR"

cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT INT TERM

############################
# Check PCA file
############################

if [[ ! -f "$EIGENVEC" ]]; then
    echo "ERROR: $EIGENVEC not found"
    exit 1
fi

############################
# Create covariate file
############################

echo "Preparing PC1–PC3 covariates..."

awk 'BEGIN{OFS="\t"}
NR==1 {print "FID","IID","PC1","PC2","PC3"}
NR>1 {print $1,$2,$3,$4,$5}' \
"$EIGENVEC" > "$TMP_DIR/pc_covariates.txt"

############################
# Run GWAS per chromosome
############################

echo "Starting GWAS by chromosome..."

for CHR in $(seq 1 22); do

    DATA="${PREFIX}${CHR}"

    echo "Processing chromosome $CHR..."

    # Check files
    if [[ ! -f "${DATA}.bed" ]]; then
        echo "  Skipping chr${CHR} (missing files)"
        continue
    fi

    OUT="${OUTDIR}/gwas_chr${CHR}"

    if [[ "$GWAS_TYPE" == "linear" ]]; then

        $PLINK \
          --bfile "$DATA" \
          --covar "$TMP_DIR/pc_covariates.txt" \
          --covar-name PC1,PC2,PC3 \
          --linear hide-covar \
          --out "$OUT"

        ASSOC_FILE="${OUT}.assoc.linear"

    elif [[ "$GWAS_TYPE" == "logistic" ]]; then

        $PLINK \
          --bfile "$DATA" \
          --covar "$TMP_DIR/pc_covariates.txt" \
          --covar-name PC1,PC2,PC3 \
          --logistic hide-covar \
          --out "$OUT"
       
        ASSOC_FILE="${OUT}.assoc.logistic"
    fi

    
    CLUMP_OUT="${OUTDIR}/gwas_clump_chr${CHR}"

    ##########################
    # Clumping
    ##########################

    echo "  Clumping chr$CHR..."

    $PLINK \
      --bfile "$DATA" \
      --clump "${ASSOC_FILE}" \
      --clump-p1 "$CLUMP_P1" \
      --clump-p2 "$CLUMP_P2" \
      --clump-r2 "$CLUMP_R2" \
      --clump-kb "$CLUMP_KB" \
      --out "$CLUMP_OUT"

done

############################
# Finished
############################

echo "GWAS and clumping completed for all chromosomes."

echo "Results in: $OUTDIR/"

echo "Example output:"
echo "  ${OUTDIR}/chr1_gwas.assoc.*"
echo "  ${OUTDIR}/gwas_clump_chr1.*"
