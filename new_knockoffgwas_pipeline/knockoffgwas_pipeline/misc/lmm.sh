#!/bin/bash
#
#
# Modified by Richard Howey for general use
# January-February 2026

# Parameters
#
# $1 = start chr number
# $2 = end chr number
# $3 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam
#      also path & file prefix (not including "_map_chrXX") for genetic map data, .txt
#      also path & file prefix (not including "_ibd_chrXX") for IBD data, .txt
# $4 = phenotype name
# $5 = output folder
# $6 = LD Table for BOLT-LMM
# $7 = Genetic map table for BOLT-LMM

# Set data dir
DATA=$(dirname "$3")

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Range of chromosomes to include in the analysis
CHR_MIN=$1
CHR_MAX=$2
CHR_LIST=$(seq $CHR_MIN $CHR_MAX)

GENO_FILE="$3_chr"
FAM_FILE="$3_chr"$CHR_MIN".fam"

PHENO_FILE=$3_phenotypes.txt
PHENO_NAME=$4

OUT_DIR=$5
mkdir -p $OUT_DIR
STATS_FILE=$OUT_DIR"/stats_chr"$CHR_MIN"_chr"$CHR_MAX"_lmm.txt"
CLUMP_BASENAME=$OUT_DIR"/clump_chr"$CHR_MIN"_chr"$CHR_MAX

CLUMP_THRESHOLD=0.00000005 # 5e-8

####################
# Compute p-values #
####################

# Stuff for bolt
LD_TABLE=$6 
MAP_TABLE=$7 

bolt \
    --bed=$GENO_FILE"{$CHR_MIN:$CHR_MAX}.bed" \
    --bim=$GENO_FILE"{$CHR_MIN:$CHR_MAX}.bim" \
    --fam=$FAM_FILE \
    --maxMissingPerSnp=1 \
    --phenoFile=$PHENO_FILE \
    --phenoCol=$PHENO_NAME \
    --covarFile=$PHENO_FILE \
    --covarCol="sex" \
    --LDscoresFile=$LD_TABLE \
    --geneticMapFile=$MAP_TABLE \
    --statsFile=$STATS_FILE \
    --lmm \
    --numThreads=1

echo "Output file:"
echo $STATS_FILE

$SCRIPTPATH/summarise_lmm.sh $1 $2 $3 $4 $5 $6 $7
