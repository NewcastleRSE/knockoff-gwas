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

# $1 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam etc.

# Set dirs
source set_dirs.sh

# List of chromosomes
CHR_LIST=$(seq 1 22)

for CHR in $CHR_LIST; do

    # Remove map data
    rm -f "$1_map_chr"$CHR".txt"

    # Remove QC data
    rm -f "$1_qc_chr"$CHR".txt"

    # Remove reformated data
    rm -f "$1_qc_chr"$CHR".sample"
    rm -f "$1_chr"$CHR".sample"
    rm -f "$1_chr"$CHR".bgen"

    # Remove IBD data
    rm -f "$1_ibd_chr"$CHR".txt"

    # Move .fam file back to original 
    [ -f "$1_original_chr"$CHR".fam" ] && mv "$1_original_chr"$CHR".fam" "$1_chr"$CHR".fam"
    [ -f "$1_original_chr"$CHR".bim" ] && mv "$1_original_chr"$CHR".bim" "$1_chr"$CHR".bim"

    # Remove phased data
    rm -f "$1_phased_chr"$CHR".log"
    rm -f "$1_phased_chr"$CHR".vcf.gz"
    rm -f "$1_phased_chr"$CHR".vcf"
    rm -f "$1_phased_chr"$CHR".bcf"
    rm -f "$1_phased_chr"$CHR".bcf.csi"
    rm -f "$1_phased_chr"$CHR".sample"
    rm -f "$1_phased_chr"$CHR".bgen"
    rm -f "$1_phased_chr"$CHR".bim"

    # Ensure temp files that should have already been deleted are (phasing)
    rm -f "$1_phased_chr"$CHR".bed"
    rm -f "$1_phased_chr"$CHR".fam"
    rm -f "$1_temp_chr"$CHR".pgen"
    rm -f "$1_temp_chr"$CHR".psam"
    rm -f "$1_temp_chr"$CHR".pvar"
    rm -f "$1_temp_chr"$CHR".log"
    rm -f "$1_temp_chr"$CHR".bim"
    rm -f "$1_temp_chr"$CHR".bed"
    rm -f "$1_temp_chr"$CHR".fam"

    rm -f "$1_temp_phased_chr"$CHR"".*
    rm -f "$1_map_chr"$CHR"_shapeit.txt"
    rm -f "$1_chr"$CHR"_shapeit.fam"

    # Ensure temp files that should have already been deleted are (IBD calc)
    rm -f "$1_map_rapid_chr"$CHR".txt" 
    
    rm -f "$1_map_filtered_chr"$CHR".txt"
    rm -f "$1_chr"$CHR".vcf.gz"
    rm -f "$1_chr"$CHR".bcf"
    rm -f "$1_chr"$CHR".bcf.csi"
    rm -f "$1_chr"$CHR".log"    
    rm -f "$1_temp_ibd_chr"$CHR".txt"

done

# Remove QC data
rm -f $1_qc_variants.txt
rm -f $1_qc_samples.txt

# Remove temporary files used for IBD calculations
rm -rf $DATA/tmp
