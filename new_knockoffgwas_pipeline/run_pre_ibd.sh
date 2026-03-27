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
# $1 = chromosome number
# $2 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam
#      also path & file prefix (not including "_map_chrXX") for genetic map data, .txt
#      also path & file prefix (not including "_ibd_chrXX") for IBD data, .txt
#      also path & file prefix (not including "_phenotypes") for all phenotype data, .txt
#      also path & file prefix (not including "_qc_chrXX") for QC SNP data, .txt
#      also path & file prefix (not including "_qc_variants") for all QC SNP data, .txt
#      also path & file prefix (not including "_qc_samples") for all QC SNP data, .txt
# $3 = phenotype name
# $4 = output folder
# $5 = -d
# $6 = -w

# Set dirs
source set_dirs.sh

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Log file
LOG_FILE=$4"/pre_knockoffgwas_"$1".log"
rm -f $LOG_FILE
touch $LOG_FILE
echo "Log file: "$LOG_FILE

# Temporary folder for temporary files
TMP_DIR=$DATA"/tmp"
mkdir -p $4
mkdir -p $TMP_DIR
mkdir -p data

# Make Phenotype file if it does not exist
if [ ! -e "$2_phenotypes.txt" ]; then
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/make_phenotype_file_from_fam.R $CHR $2 $3 &>> $LOG_FILE
fi

# Setup spinner for long jobs
source "$SCRIPTPATH/knockoffgwas_pipeline/misc/spinner.sh"


# List of chromosomes
CHR_LIST=$(seq $1 $1)


# Calculate IBD segments for each chromosome
for CHR in $CHR_LIST; do

    echo ""
    echo "Creating IBD data for chromosome "$CHR" ..."
    echo ""

    # Make directory for results
    mkdir -p $TMP_DIR/"ibd_chr"$CHR

    # Create .vcf file
    if [ ! -e "$2_phased_chr${CHR}.vcf" ] && [ ! -e "$2_phased_chr${CHR}.vcf.gz" ]; then
        if [ -e "$2_phased_chr${CHR}.bcf" ]; then
          bcftools view "$2_phased_chr${CHR}.bcf" -Ov -o "$2_phased_chr${CHR}.vcf" &>> $LOG_FILE
        else
          echo "$2_phased_chr${CHR}.vcf" file not present!
          exit 1
        fi
    fi
        
    # Zip up
    if [ ! -e "$2_phased_chr${CHR}.vcf.gz" ] && [ -e "$2_phased_chr${CHR}.vcf" ]; then
        echo gzipping file "$2_phased_chr${CHR}.vcf"
        gzip -f "$2_phased_chr${CHR}.vcf"
    fi

    # Produce genetic map file for use with RaPID using python conversion scripts provided by RaPID
    
    echo "Filtering map file..." 
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/filter_mapping_file.R "$2_map_chr${CHR}.txt" "$2_map_filtered_chr${CHR}.txt" &>> $LOG_FILE
    
    echo "Interpolating loci..."
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/interpolate_loci.R "$2_map_filtered_chr${CHR}.txt" "$2_phased_chr${CHR}.vcf.gz" "$2_map_rapid_chr${CHR}.txt" &>> $LOG_FILE
    
    # Usage: ./RaPID_v.1.7 -i <input_file_vcf_compressed> -g <genetic_mapping_file> -d <min_length_in_cM> -o <output_folder> -w  <window_size> -r <#runs> -s <#success>
    
    $SCRIPTPATH/knockoffgwas_pipeline/new_bits/RaPID_v.1.7 -i "$2_phased_chr${CHR}.vcf.gz" -g "$2_map_rapid_chr${CHR}.txt" -d $5 -w $6 -r 10 -s 5 -o $TMP_DIR/"ibd_chr"$CHR &>> $LOG_FILE

    gunzip -f $TMP_DIR/"ibd_chr"$CHR/results.max.gz
    mv $TMP_DIR/"ibd_chr"$CHR/results.max "$2_temp_ibd_chr${CHR}.txt"

    # Convert IBD format from RaPIDv1.7 to v1.2.3
    if [ -s "$2_temp_ibd_chr${CHR}.txt" ]; then
       Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_ibd_format3.R "$2_temp_ibd_chr${CHR}.txt" "$2_ibd_chr${CHR}.txt" &>> $LOG_FILE
    else
       touch "$2_ibd_chr${CHR}.txt"
    fi

    # Remove temporary files
    rm -f "$2_map_rapid_chr"$CHR".txt" 
    
    rm -f "$2_map_filtered_chr"$CHR".txt"
    rm -f "$2_chr"$CHR".vcf.gz"
    rm -f "$2_chr"$CHR".bcf"
    rm -f "$2_chr"$CHR".bcf.csi"
    rm -f "$2_chr"$CHR".log"    
    rm -f "$2_temp_ibd_chr"$CHR".txt"

done

# Make QC files required for the pipeline if they do not exist:
# $2_variants.txt and $2_qc_chrXX.txt
# $2_qc_samples.txt
# If they do not exist we assume the QC has already been done we just choose all SNPs and individuals
# R libraries

start_spinner " - Creating QC files (if necessary) for KnockOffGWAS pipeline..."
Rscript --vanilla "$SCRIPTPATH/knockoffgwas_pipeline/new_bits/make_qc_files.R" $1 $1 $2 $4 &>> $LOG_FILE
stop_spinner $?

