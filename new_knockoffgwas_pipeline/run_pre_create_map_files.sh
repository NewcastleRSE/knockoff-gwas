#!/bin/bash
#
# Class: script
#
# Run KnockoffGWAS on any dataset
#
# Authors: Richard Howey
# Date:    20/03/2026
#
# Parameters
#
# $1 = start chr number
# $2 = end chr number
# $3 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam
#      also path & file prefix (not including "_map_chrXX") for genetic map data, .txt
#      also path & file prefix (not including "_ibd_chrXX") for IBD data, .txt
#      also path & file prefix (not including "_phenotypes") for all phenotype data, .txt
#      also path & file prefix (not including "_qc_chrXX") for QC SNP data, .txt
#      also path & file prefix (not including "_qc_variants") for all QC SNP data, .txt
#      also path & file prefix (not including "_qc_samples") for all QC SNP data, .txt
# $4 = output folder   
# $5 = genetic map data for each chr, path and file, but not including end which must be "_chrXX.txt" for each chr separately

# Set dirs
source set_dirs.sh

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Log file
LOG_FILE=$4"/pre_knockoffgwas_create_map_files_"$1"_"$2".log"
rm -f $LOG_FILE
touch $LOG_FILE
echo "Log file: "$LOG_FILE

# Temporary folder for temporary files
TMP_DIR=$DATA"/tmp"
mkdir -p $4
mkdir -p $TMP_DIR
mkdir -p data

# Run interpolate_genetic_map.R for chromosomes 1-22
R_SCRIPT=$SCRIPTPATH/knockoffgwas_pipeline/new_bits/interpolate_genetic_map.R

for CHR in $(seq $1 $2); do
    MAP_FILE="$5_chr"$CHR".txt"
    BIM_FILE="$3_chr"$CHR".bim"
    OUT_FILE="$3_map_chr"$CHR".txt"

    if [[ ! -f "$MAP_FILE" ]]; then
        echo "Warning: $MAP_FILE not found, skipping chromosome $CHR"
        continue
    fi

    if [[ ! -f "$BIM_FILE" ]]; then
        echo "Warning: $BIM_FILE not found, skipping chromosome $CHR"
        continue
    fi

    echo "Processing chromosome $CHR ..."
    Rscript "$R_SCRIPT" "$MAP_FILE" "$BIM_FILE" "$OUT_FILE"
done

echo "All done!"
