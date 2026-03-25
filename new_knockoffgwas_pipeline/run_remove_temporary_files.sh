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

    # Remove reformated data
    rm -f "$3_qc_chr"$CHR".sample"
    rm -f "$3_chr"$CHR".sample"
    rm -f "$3_chr"$CHR".bgen"

    # Remove IBD data
    rm -f "$3_ibd_chr"$CHR".txt"

    # Move .fam file back to original 
    mv "$3_original_chr"$CHR".fam" "$3_chr"$CHR".fam"

    # Remove phased data
    rm -f "$3_phased_chr"$CHR".log"
    rm -f "$3_phased_chr"$CHR".vcf.gz"
    rm -f "$3_phased_chr"$CHR".vcf"
    rm -f "$3_phased_chr"$CHR".bcf"
    rm -f "$3_phased_chr"$CHR".bcf.csi"

done

# Remove QC data
rm -f $3_qc_variants.txt
rm -f $3_qc_samples.txt

# Remove temporary files used for IBD calculations
rm -rf $DATA/tmp
