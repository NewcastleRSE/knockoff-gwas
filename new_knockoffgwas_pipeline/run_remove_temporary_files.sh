#!/bin/bash
#
# Class: script
#
# Run KnockoffGWAS on any dataset
# Remove all intermediate files used for analysis
#
# Authors: Richard Howey
# Date:    28/03/2025
#

# $1 = start chr number
# $2 = end chr number
# $3 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam etc.

# Set dirs
source set_dirs.sh

# List of chromosomes
CHR_LIST=$(seq $1 $2)


for CHR in $CHR_LIST; do

    rm -f "$3_qc_chr"$CHR".sample"
    rm -f "$3_chr"$CHR".sample"
    rm -f "$3_chr"$CHR".bgen"
    rm -f "$3_ibd_chr"$CHR".txt"

    # Move .fam file back to original 
    mv "$3_original_chr"$CHR".fam" "$3_chr"$CHR".fam"

done

rm -f $3_qc_variants.txt
rm -rf $DATA/tmp

rmdir ibd