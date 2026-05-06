#!/bin/bash
#
# Class: script
#
# Run BOLT-LMM on any dataset
#
# Authors: Richard Howey
# Date:    15/01/2026
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
# $5 = output folder
# $6 = LD Table for BOLT-LMM
# $7 = Genetic map table for BOLT-LMM

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Load dirs
source ./set_dirs.sh

# Output folder
mkdir -p $5

$SCRIPTPATH/knockoffgwas_pipeline/misc/lmm.sh $1 $2 $3 $4 $5 $6 $7


