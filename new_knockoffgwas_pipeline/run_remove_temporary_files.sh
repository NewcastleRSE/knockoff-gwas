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
    mv "$3_original_chr"$CHR".bim" "$3_chr"$CHR".bim"

    # Remove phased data
    rm -f "$3_phased_chr"$CHR".log"
    rm -f "$3_phased_chr"$CHR".vcf.gz"
    rm -f "$3_phased_chr"$CHR".vcf"
    rm -f "$3_phased_chr"$CHR".bcf"
    rm -f "$3_phased_chr"$CHR".bcf.csi"
    rm -f "$3_phased_chr"$CHR".sample"
    rm -f "$3_phased_chr"$CHR".bgen"
    rm -f "$3_phased_chr"$CHR".bim"

    # Ensure temp files that should have already been deleted are (phasing)
    rm -f "$3_phased_chr"$CHR".bed"
    rm -f "$3_phased_chr"$CHR".fam"
    rm -f "$3_temp_chr"$CHR".pgen"
    rm -f "$3_temp_chr"$CHR".psam"
    rm -f "$3_temp_chr"$CHR".pvar"
    rm -f "$3_temp_chr"$CHR".log"
    rm -f "$3_temp_chr"$CHR".bim"
    rm -f "$3_temp_chr"$CHR".bed"
    rm -f "$3_temp_chr"$CHR".fam"

    rm -f "$3_temp_phased_chr"$CHR"".*
    rm -f "$3_map_chr"$CHR"_shapeit.txt"
    rm -f "$3_chr"$CHR"_shapeit.fam"

    # Ensure temp files that should have already been deleted are (IBD calc)
    rm -f "$3_map_rapid_chr"$CHR".txt" 
    
    rm -f "$3_map_filtered_chr"$CHR".txt"
    rm -f "$3_chr"$CHR".vcf.gz"
    rm -f "$3_chr"$CHR".bcf"
    rm -f "$3_chr"$CHR".bcf.csi"
    rm -f "$3_chr"$CHR".log"    
    rm -f "$3_temp_ibd_chr"$CHR".txt"

done

# Remove QC data
rm -f $3_qc_variants.txt
rm -f $3_qc_samples.txt

# Remove temporary files used for IBD calculations
rm -rf $DATA/tmp
