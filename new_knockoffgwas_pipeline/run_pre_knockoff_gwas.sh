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
# $7 = -l
# $8 = -w

# Set dirs
source set_dirs.sh

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Log file
LOG_FILE=$6"/pre_knockoffgwas_"$1"_"$2".log"
rm -f $LOG_FILE
touch $LOG_FILE
echo "Log file: "$LOG_FILE

# Temporary folder for temporary files
TMP_DIR=$DATA"/tmp"
mkdir -p $6
mkdir -p $TMP_DIR
mkdir -p data

# Setup spinner for long jobs
source "$SCRIPTPATH/knockoffgwas_pipeline/misc/spinner.sh"

# Make QC files required for the pipeline if they do not exist:
# $3_variants.txt and $3_qc_chrXX.txt
# $3_samples.txt
# If they do not exist we assume the QC has already been done we just choose all SNPs and individuals
# R libraries

start_spinner " - Creating QC files (if necessary) for KnockOffGWAS pipeline..."
Rscript --vanilla "$SCRIPTPATH/knockoffgwas_pipeline/new_bits/make_qc_files.R" $1 $2 $3 $6 &>> $LOG_FILE
stop_spinner $?

# List of chromosomes
CHR_LIST=$(seq $1 $2)

# If haplotype data exists, .bgen, .sample then it is used otherwise it is calculated

start_spinner " - Phasing chromosome data (if necessary) for KnockOffGWAS pipeline..."
for CHR in $CHR_LIST; do

if [ -e "$3_phased_chr"$CHR".bgenXXX" ]; then
    echo ""
    echo "Phasing for chromosome "$CHR" exists"
    echo ""
else
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

    cp "$3_chr"$CHR".vcf".gz data/"_chr"$CHR".vcf".gz
    
#echo "=== Node ==="
    #hostname

    #echo "=== File size seen by compute node ==="
    #ls -l $DATA/Nicola_chr22.vcf.gz
  
    #echo "=== md5sum seen by compute node ==="
    #md5sum $DATA/Nicola_chr22.vcf.gz
    #echo "=== trying random read test ==="
#zcat $DATA/Nicola_chr22.vcf.gz | wc -l

#echo "=== seek test ==="
#zgrep -m 1 -n "rs123" $DATA/Nicola_chr22.vcf.gz
echo "--- bcftools version ---"
bcftools --version

echo "--- which bcftools ---"
which bcftools

echo "--- ldd bcftools ---"
ldd $(which bcftools)


    # Convert to bcf
    bcftools view -Ob data/"_chr"$CHR".vcf".gz -o data/"_chr"$CHR".bcf" &>> $LOG_FILE
       
    # Fill in missing AC (allele count) field
    bcftools +fill-tags data/"_chr"$CHR".bcf" -Ob -o data/"_chr"$CHR".bcf" -- -t AN,AC &>> $LOG_FILE      
    
    # Create index file
    bcftools index data/"_chr"$CHR".bcf" &>> $LOG_FILE
    
    # Create pedigree file for Shapeit5, This file contains one line per sample having parent(s) in the dataset and three columns (kidID fatherID and motherID), separated by TABs for spaces.
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_ped_file.R $GENO_FAM "$3_chr"$CHR"_shapeit.fam" &>> $LOG_FILE

    # Convert map file by removing the first column (chr)
    cut -f2- "$3_map_chr"$CHR".txt" > "$3_map_chr"$CHR"_shapeit.txt"
    
    # Phase
    $SCRIPTPATH/knockoffgwas_pipeline/new_bits/phase_common_static --input data/"_chr"$CHR".bcf" --pedigree "$3_chr"$CHR"_shapeit.fam" --region $CHR --map "$3_map_chr"$CHR"_shapeit.txt" --output data/"_phased_chr"$CHR".bcf" --thread 8 &>> $LOG_FILE

    # Convert phased chr to bgen
    # bcftools convert --bgen-plain --output-type b --output "$3_chr"$CHR".bgen" "$3_phased_chr"$CHR".bcf" &>> $LOG_FILE
    
    # Create .sample file?

    bcftools view data/"_phased_chr"$CHR".bcf" -Ov -o "$3_phased_chr"$CHR".vcf" &>> $LOG_FILE
 
    plink2 --vcf "$3_phased_chr"$CHR".vcf" --make-pgen --out "$3_temp_chr"$CHR"" &>> $LOG_FILE

    plink2 --pfile "$3_temp_chr"$CHR"" --export bgen-1.2 ref-first id-paste=iid --out "$3_chr"$CHR"" &>> $LOG_FILE

    cp "$3_chr"$CHR".sample" "$3_temp_chr"$CHR".sample"

    # Fixed .sample file to have the same family and individual ID
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_sample_format.R "$3_temp_chr"$CHR".sample" "$3_chr"$CHR".sample" &>> $LOG_FILE

    # Remove temporary files
    #rm -f data/*${CHR}*
    rm -f "$3_temp_chr"$CHR"".*
    rm -f "$3_map_chr"$CHR"_shapeit.txt"
    rm -f "$3_chr"$CHR"_shapeit.fam"
    rm -f "$3_phased_chr"$CHR".vcf"
    rm -f "$3_phased_chr"$CHR".bcf"
    rm -f "$3_phased_chr"$CHR".bcf.csi"
fi
    
done
stop_spinner $?


# Make directory for results
# mkdir -p ibd

# If IBD data exists, .txt, then it is used otherwise it is calculated
for CHR in $CHR_LIST; do

# Remove to redo IBD calcs
#rm "$3_ibd_chr"$CHR".txt"

if [ -e "$3_ibd_chr"$CHR".txt" ]; then
    echo "IBD data for chromosome "$CHR" exists"
else
    echo ""
    echo "Creating IBD data for chromosome "$CHR" ..."
    echo ""

    # Make directory for results
    mkdir -p $TMP_DIR/"ibd_chr"$CHR

    # Create .vcf file
    if [ -e "$3_chr"$CHR".vcf" ]; then
        plink --bfile "$3_chr"$CHR --recode vcf --out "$3_chr"$CHR
    fi
    
    # Zip up
    gzip -f "$3_chr"$CHR".vcf"
    
    # Produce genetic map file for use with RaPID using python conversion scripts provided by RaPID
    #python $SCRIPTPATH/knockoffgwas_pipeline/new_bits/filter_mapping_file.py "$3_map_chr"$CHR".txt" "$3_map_filtered_chr"$CHR".txt"
    #python $SCRIPTPATH/knockoffgwas_pipeline/new_bits/interpolate_loci.py "$3_map_filtered_chr"$CHR".txt" "$3_chr"$CHR".vcf.gz" "$3_map_rapid_chr"$CHR".txt"
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/filter_mapping_file.R "$3_map_chr"$CHR".txt" "$3_map_filtered_chr"$CHR".txt" &>> $LOG_FILE
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/interpolate_loci.R "$3_map_filtered_chr"$CHR".txt" "$3_chr"$CHR".vcf.gz" "$3_map_rapid_chr"$CHR".txt" &>> $LOG_FILE
    
    # Usage: ./RaPID_v.1.7 -i <input_file_vcf_compressed>  -g <genetic_mapping_file> -d <min_length_in_cM> -o <output_folder>   -w  <window_size>  -r <#runs> -s <#success>
    #$SCRIPTPATH/knockoffgwas_pipeline/new_bits/RaPID_v.1.7 -i "$3_chr"$CHR".vcf.gz" -g "$3_map_rapid_chr"$CHR".txt" -d 5 -w 250 -r 10 -s 2 -o ibd_"$3_chr"$CHR &>> $LOG_FILE
    $SCRIPTPATH/knockoffgwas_pipeline/new_bits/RaPID_v.1.7 -i "$3_chr"$CHR".vcf.gz" -g "$3_map_rapid_chr"$CHR".txt" -d $7 -w $8 -r 10 -s 5 -o $TMP_DIR/"ibd_chr"$CHR &>> $LOG_FILE

    # Required:
    # <INPUT FILE> <OUTPUT FOLDER> <WINDOW SIZE> <NUMBER OF RUNS> <NUMBER OF SUCCESSES> <MINIMUM IBD LENGTH>
    # <TOTAL LENGTH> required if minimum IBD length is given in cM or Mbps

    #$SCRIPTPATH/knockoffgwas_pipeline/new_bits/RaPID_v.1.2.3 -i "$3_chr"$CHR".vcf.gz" -g "$3_map_rapid_chr"$CHR".txt" -d $7 -w $8 -r 10 -s 5 -o $TMP_DIR/"ibd_chr"$CHR &>> $LOG_FILE

    gunzip -f $TMP_DIR/"ibd_chr"$CHR/results.max.gz
    mv $TMP_DIR/"ibd_chr"$CHR/results.max "$3_temp_ibd_chr"$CHR".txt"

    # Convert IBD format from RaPIDv1.7 to v1.2.3
    Rscript --vanilla $SCRIPTPATH/knockoffgwas_pipeline/new_bits/convert_ibd_format3.R "$3_temp_ibd_chr"$CHR".txt" "$3_ibd_chr"$CHR".txt"

    # Remove temporary files
    rm -f "$3_map_rapid_chr"$CHR".txt" 
    rm -f "$3_chr"$CHR".vcf.gz"
    rm -f "$3_chr"$CHR".vcf"
    rm -f "$3_map_filtered_chr"$CHR".txt"
fi
    
done


