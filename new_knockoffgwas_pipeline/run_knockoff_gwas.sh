#!/bin/bash
#
# Class: script
#
# Run KnockoffGWAS on any dataset
#
# Authors: Richard Howey
# Date:    28/03/2025
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
# $4 = phenotype name
# $5 = FDR rate
# $6 = output folder

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Temporary folder for temporary files
TMP_DIR=$6"/tmp"
mkdir -p $6
mkdir -p $TMP_DIR

$SCRIPTPATH/knockoffgwas_pipeline/analyze.sh $1 $2 $3 $4 $5 $6 


