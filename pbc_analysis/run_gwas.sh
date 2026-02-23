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
CLUMP_R2=0.1
CLUMP_KB=5000

CHR_MIN=1
CHR_MAX=22

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

for CHR in $(seq $CHR_MIN $CHR_MAX); do

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

# Parse clumped p-values and summarise discoveries all together
# Put all chr1_gwas.assoc.* in one file
# Put all gwas_clump_chr1.* in one file

STATS_FILE=${OUT_DIR}"/stats_chr"$CHR_MIN"_chr"$CHR_MAX"_lmm.txt"
CLUMP_FILE=${OUT_DIR}"/clump_chr"$CHR_MIN"_chr"$CHR_MAX".tab"
OUT_FILE=${OUTDIR}/$CLUMP_BASENAME"_lmm_regions.txt"

STATS_FILE="${OUT_DIR}/stats_chr${CHR_MIN}_chr${CHR_MAX}_lmm.txt"
CLUMP_FILE="${OUT_DIR}/clump_chr${CHR_MIN}_chr${CHR_MAX}.tab"

# Remove output files if they already exist
rm -f "$STATS_FILE" "$CLUMP_FILE"

first_stats=1
first_clump=1

for CHR in $(seq $CHR_MIN $CHR_MAX); do

    stats_in="${OUTDIR}/chr${CHR}_gwas.assoc."
    clump_in="${OUTDIR}/gwas_clump_chr${CHR}."*

    # ---- Combine GWAS stats ----
    if [ -f "$stats_in" ]; then
        if [ $first_stats -eq 1 ]; then
            cat "$stats_in" >> "$STATS_FILE"
            first_stats=0
        else
            tail -n +2 "$stats_in" >> "$STATS_FILE"
        fi
    fi

    # ---- Combine clump files ----
    for f in $clump_in; do
        if [ -f "$f" ]; then
            if [ $first_clump -eq 1 ]; then
                cat "$f" >> "$CLUMP_FILE"
                first_clump=0
            else
                tail -n +2 "$f" >> "$CLUMP_FILE"
            fi
        fi
    done

done

Rscript --vanilla $SCRIPTPATH/summarise_lmm.R ${CLUMP_FILE} ${OUT_FILE} $1 ${STATS_FILE} 1

