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
# $5 = output folder

# Set dirs
source set_dirs.sh

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Log file
LOG_FILE=$5"/pre_knockoffgwas_"$1"_"$2".log"
rm -f $LOG_FILE
touch $LOG_FILE
echo "Log file: "$LOG_FILE

# Temporary folder for temporary files
TMP_DIR=$DATA"/tmp"
mkdir -p $5
mkdir -p $TMP_DIR
mkdir -p data

# Make Phenotype file if it does not exist
if [ ! -e "$3_phenotypes.txt" ]; then
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/make_phenotype_file_from_fam.R $CHR $3 $4 &>> $LOG_FILE
fi

# Setup spinner for long jobs
source "$SCRIPTPATH/knockoffgwas_pipeline/misc/spinner.sh"

# List of chromosomes
CHR_LIST=$(seq $1 $2)

start_spinner " - Phasing chromosome data for KnockOffGWAS pipeline..."
for CHR in $CHR_LIST; do

    echo ""
    echo "Phasing chromosome "$CHR" ..."
    echo ""

    # Input genotype files (PLINK format)
    GENO_BIM="$3_chr"$CHR".bim"

    # Input genotype files (PLINK format)
    GENO_FAM="$3_chr"$CHR".fam"

    cp $GENO_FAM "$3_original_chr"$CHR".fam"

    # Convert.fam file to numbered IDs
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_fam_format.R "$3_original_chr"$CHR".fam" $GENO_FAM   

    # Create .vcf file
    plink2 --bfile "$3_chr"$CHR --recode vcf --out "$3_chr"$CHR &>> $LOG_FILE
       
    gzip -f "$3_chr"$CHR".vcf"

    # Convert to bcf
    bcftools view -Ob "$3_chr"$CHR".vcf".gz -o "$3_chr"$CHR".bcf" &>> $LOG_FILE
       
    # Fill in missing AC (allele count) field
    bcftools +fill-tags "$3_chr"$CHR".bcf" -Ob -o "$3_temp_chr"$CHR".bcf" -- -t AN,AC &>> $LOG_FILE      
    
    mv "$3_temp_chr"$CHR".bcf" "$3_chr"$CHR".bcf"

    # Create index file
    bcftools index "$3_chr"$CHR".bcf" &>> $LOG_FILE
    
    # Create pedigree file for Shapeit5, This file contains one line per sample having parent(s) in the dataset and three columns (kidID fatherID and motherID), separated by TABs for spaces.
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_ped_file.R $GENO_FAM "$3_chr"$CHR"_shapeit.fam" &>> $LOG_FILE

    # Convert map file by removing the first column (chr)
    cut -f2- "$3_map_chr"$CHR".txt" > "$3_map_chr"$CHR"_shapeit.txt"
    
    # Phase
    $SCRIPTPATH/knockoffgwas_pipeline/new_bits/phase_common_static --input "$3_chr"$CHR".bcf" --pedigree "$3_chr"$CHR"_shapeit.fam" --region $CHR --map "$3_map_chr"$CHR"_shapeit.txt" --output "$3_phased_chr"$CHR".bcf" --thread 8 &>> $LOG_FILE

    # Convert phased chr to bgen
    # Also, create .sample file

    bcftools view "$3_phased_chr"$CHR".bcf" -Ov -o "$3_phased_chr"$CHR".vcf" &>> $LOG_FILE
 
    plink2 --vcf "$3_phased_chr"$CHR".vcf" --make-pgen --out "$3_temp_chr"$CHR"" &>> $LOG_FILE

    plink2 --pfile "$3_temp_chr"$CHR"" --export bgen-1.2 ref-first id-paste=iid --out "$3_phased_chr"$CHR"" &>> $LOG_FILE

    cp "$3_phased_chr"$CHR".sample" "$3_temp_phased_chr"$CHR".sample"

    # Fixed .sample file to have the same family and individual ID
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_sample_format.R "$3_temp_phased_chr"$CHR".sample" "$3_phased_chr"$CHR".sample" &>> $LOG_FILE

    # Create .bim file for phased data
    plink2 --bgen "$3_phased_chr"$CHR".bgen" ref-first --sample "$3_phased_chr"$CHR".sample" --make-bed --out "$3_phased_chr"$CHR""

    # Remove .bed and .fam
    rm -f "$3_phased_chr"$CHR".bed"
    rm -f "$3_phased_chr"$CHR".fam"

    # Remove temporary files
    rm -f "$3_temp_chr"$CHR".pgen"
    rm -f "$3_temp_chr"$CHR".psam"
    rm -f "$3_temp_chr"$CHR".pvar"
    rm -f "$3_temp_chr"$CHR".log"
    rm -f "$3_temp_chr"$CHR".bim"
   
    rm -f "$3_temp_phased_chr"$CHR"".*
    rm -f "$3_map_chr"$CHR"_shapeit.txt"
    rm -f "$3_chr"$CHR"_shapeit.fam"
    
done
stop_spinner $?


