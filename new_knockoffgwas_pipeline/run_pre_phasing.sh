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

# Set data dir
DATA=$(dirname "$2")

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

# Make Phenotype file if it does not exist
if [ ! -e "$2_phenotypes.txt" ]; then
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/make_phenotype_file_from_fam.R $CHR $2 $3 &>> $LOG_FILE
fi

# Setup spinner for long jobs
source "$SCRIPTPATH/knockoffgwas_pipeline/misc/spinner.sh"

# List of chromosomes
CHR_LIST=$(seq $1 $1)

start_spinner " - Phasing chromosome data for KnockOffGWAS pipeline..."
for CHR in $CHR_LIST; do

    echo ""
    echo "Phasing chromosome "$CHR" ..."
    echo ""

    # Input genotype files (PLINK format)
    GENO_BIM="$2_chr"$CHR".bim"

    # Input genotype files (PLINK format)
    GENO_FAM="$2_chr"$CHR".fam"

    cp $GENO_FAM "$2_original_chr"$CHR".fam"

    # Convert.fam file to numbered IDs
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_fam_format.R "$2_original_chr"$CHR".fam" $GENO_FAM   

    # Create .vcf file
    plink2 --bfile "$2_chr"$CHR --recode vcf --out "$2_chr"$CHR &>> $LOG_FILE
       
    gzip -f "$2_chr"$CHR".vcf"

    # Convert to bcf
    bcftools view -Ob "$2_chr"$CHR".vcf".gz -o "$2_chr"$CHR".bcf" &>> $LOG_FILE
       
    # Fill in missing AC (allele count) field
    bcftools +fill-tags "$2_chr"$CHR".bcf" -Ob -o "$2_temp_chr"$CHR".bcf" -- -t AN,AC &>> $LOG_FILE      
    
    mv "$2_temp_chr"$CHR".bcf" "$2_chr"$CHR".bcf"

    # Create index file
    bcftools index "$2_chr"$CHR".bcf" &>> $LOG_FILE
    
    # Create pedigree file for Shapeit5, This file contains one line per sample having parent(s) in the dataset and three columns (kidID fatherID and motherID), separated by TABs for spaces.
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_ped_file.R $GENO_FAM "$2_chr"$CHR"_shapeit.fam" &>> $LOG_FILE

    # Convert map file by removing the first column (chr)
    cut -f2- "$2_map_chr"$CHR".txt" > "$2_map_chr"$CHR"_shapeit.txt"
    
    # Phase
    $SCRIPTPATH/knockoffgwas_pipeline/new_bits/phase_common_static --input "$2_chr"$CHR".bcf" --pedigree "$2_chr"$CHR"_shapeit.fam" --region $CHR --map "$2_map_chr"$CHR"_shapeit.txt" --output "$2_phased_chr"$CHR".bcf" --thread 8 &>> $LOG_FILE

    # Convert phased chr to bgen
    # Also, create .sample file

    bcftools view "$2_phased_chr"$CHR".bcf" -Ov -o "$2_phased_chr"$CHR".vcf" &>> $LOG_FILE
 
    plink2 --vcf "$2_phased_chr"$CHR".vcf" --make-pgen --out "$2_temp_chr"$CHR"" &>> $LOG_FILE

    plink2 --pfile "$2_temp_chr"$CHR"" --export bgen-1.2 ref-first id-paste=iid --out "$2_phased_chr"$CHR"" &>> $LOG_FILE

    cp "$2_phased_chr"$CHR".sample" "$2_temp_phased_chr"$CHR".sample"

    # Fixed .sample file to have the same family and individual ID
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_sample_format.R "$2_temp_phased_chr"$CHR".sample" "$2_phased_chr"$CHR".sample" &>> $LOG_FILE

    # Create .bim file for phased data
    plink2 --bgen "$2_phased_chr"$CHR".bgen" ref-first --sample "$2_phased_chr"$CHR".sample" --make-bed --out "$2_phased_chr"$CHR""

    # Remove .bed and .fam
    rm -f "$2_phased_chr"$CHR".bed"
    rm -f "$2_phased_chr"$CHR".fam"

    # Remove temporary files
    rm -f "$2_temp_chr"$CHR".pgen"
    rm -f "$2_temp_chr"$CHR".psam"
    rm -f "$2_temp_chr"$CHR".pvar"
    rm -f "$2_temp_chr"$CHR".log"
    rm -f "$2_temp_chr"$CHR".bim"
   
    rm -f "$2_temp_phased_chr"$CHR"".*
    rm -f "$2_map_chr"$CHR"_shapeit.txt"
    rm -f "$2_chr"$CHR"_shapeit.fam"
    
done
stop_spinner $?


