#!/bin/bash
#
#
# Modified by Richard Howey for general use
# January-February 2026

# Parameters
#
# $1 = Chromosome number
# $2 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam
#      also path & file prefix (not including "_map_chrXX") for genetic map data, .txt
#      also path & file prefix (not including "_ibd_chrXX") for IBD data, .txt
# $3 = phenotype name
# $4 = output folder

# Set dirs
source ./set_dirs.sh

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Range of chromosomes to include in the analysis
CHR_MIN=$1
CHR_MAX=$2
CHR_LIST=$(seq $CHR_MIN $CHR_MAX)

GENO_FILE="$2_chr"
FAM_FILE="$2_chr"$CHR_MIN".fam"

PHENO_FILE=$2_phenotypes.txt
PHENO_NAME=$3

OUT_DIR="$4/lmm"
mkdir -p $OUT_DIR
STATS_FILE=$OUT_DIR"/stats_chr"$CHR_MIN"_chr"$CHR_MAX"_lmm.txt"
CLUMP_BASENAME=$OUT_DIR"/clump_chr"$CHR_MIN"_chr"$CHR_MAX

CLUMP_THRESHOLD=0.00000005 # 5e-8

#####################
# Clump nearby loci #
#####################

# Create temporary stats file with modified header
STATS_FILE_TMP=$STATS_FILE".tmp"
head -n 1 $STATS_FILE > $STATS_FILE_TMP
sed -i 's/\S\+$/P/' $STATS_FILE_TMP
tail -n +2 $STATS_FILE >> $STATS_FILE_TMP

for CHR in $CHR_LIST; do
# Clumping of LMM p-values
CLUMP_FILE=$CLUMP_BASENAME"_lmm_clumped"
echo "Clumping chromosome $CHR at threshold $CLUMP_THRESHOLD"
plink --bfile $GENO_FILE$CHR \
--clump $STATS_FILE_TMP \
--clump-p1 $CLUMP_THRESHOLD \
--clump-r2 0.01 \
--clump-kb 5000 \
--out $CLUMP_FILE"_chr"$CHR
rm -f $CLUMP_FILE"_chr"$CHR".log"
rm -f $CLUMP_FILE"_chr"$CHR".nosex"
done

# Erase temporary stats file with modified header
rm $STATS_FILE_TMP

# Combine results of clumping into a single file
echo "Combining clumping files at threshold $CLUMP_THRESHOLD"
CLUMP_FILE=$CLUMP_BASENAME"_lmm_clumped"
# Write header
HEADER=" CHR    F             SNP         BP        P    TOTAL   NSIG    S05    S01   S001  S0001    SP2"
echo $HEADER > $CLUMP_FILE".tab"
for CHR in $CHR_LIST; do
if [ -s $CLUMP_FILE"_chr"$CHR".clumped" ]; then
tail -n +2 $CLUMP_FILE"_chr"$CHR".clumped" >> $CLUMP_FILE".tab"
rm $CLUMP_FILE"_chr"$CHR".clumped"
fi
done
# Remove empty lines
sed -i '/^$/d' $CLUMP_FILE".tab"
echo "Results written on "$CLUMP_FILE".tab"

# Parse clumped p-values and summarise discoveries
OUT_FILE=$CLUMP_BASENAME"_lmm_regions.txt"
Rscript --vanilla $SCRIPTPATH/summarise_lmm.R $CLUMP_FILE".tab" ${OUT_FILE} $2 $STATS_FILE
