#!/bin/bash
# UK Biobank GWAS
#
# Class: script
#
# Run KnockoffGWAS on a toy dataset
#
# Authors: Matteo Sesia
# Date:    04/24/2019
#
# Modified by Richard Howey for general use
# March 2025

# Parameters
#
# $1 = start chr number
# $2 = end chr number
# $3 = path & file prefix (not including "_chrXX") for genetic data, .bim, .bed, .fam
#      also path & file prefix (not including "_map_chrXX") for genetic map data, .txt
#      also path & file prefix (not including "_ibd_chrXX") for genetic map data, .txt
# $4 = phenotype name
# $5 = FDR rate
# $6 = output folder

# If haplotype data exists, .bgen, .sample then it is used otherwise it is calculated
# If IBD data exists, .txt, then it is used otherwise it is calculated

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

#########
# Setup #
#########

# Print header
printf "KnockoffGWAS (27 July 2021) \n"
printf "https://bitbucket.org/msesia/knockoffgwas \n"
printf "(C) 2020,2021 Matteo Sesia   GNU General Public License v3 \n\n"

# Setup spinner for long jobs
source "$SCRIPTPATH/misc/spinner.sh"

# Log file
LOG_FILE=$6"/knockoffgwas.log"
rm -f $LOG_FILE
touch $LOG_FILE
echo "Log file: "$LOG_FILE

# Enter the directory where the scripts are stored
# cd knockoffgwas

######################
# Check dependencies #
######################

printf "\nSetup\n"
# System dependencies
ERROR=0
check_dependency () {
  CMD=$1
  if [ ! -x "$(command -v $CMD)" ]; then
    echo -e "Error: command $CMD not available"
    ERROR=1
  fi
}
DEPENDENCY_LIST=("plink" "R" "$SCRIPTPATH/snpknock2/bin/snpknock2")
start_spinner " - Checking system dependencies..."
for DEPENDENCY in "${DEPENDENCY_LIST[@]}"; do
  check_dependency $DEPENDENCY &>> $LOG_FILE
done
stop_spinner $ERROR

# R libraries
start_spinner " - Checking R library dependencies..."
Rscript --vanilla "$SCRIPTPATH/knockoffgwas/utils/check_packages.R" &>> $LOG_FILE
stop_spinner $?

####################
# Run KnockoffGWAS #
####################

printf "\nData analysis\n"

# Module 1: partition the genome into LD blocks
start_spinner ' - Running module 1  (partitioning the genome)...'
$SCRIPTPATH/knockoffgwas/module_1_partition.sh $1 $2 $3 $4 $5 $6 &>> $LOG_FILE
stop_spinner $?

# Module 2: generate the knockoffs
start_spinner ' - Running module 2  (generating knockoffs)...'
$SCRIPTPATH/knockoffgwas/module_2_knockoffs.sh $1 $2 $3 $4 $5 $6 &>> $LOG_FILE
stop_spinner $?

# Module 2b: evaluate the goodness of fit of the knockoffs
start_spinner ' - Running module 2b (evaluating knockoffs quality)...'
$SCRIPTPATH/knockoffgwas/module_2b_knockoffs_gof.sh $1 $2 $3 $4 $5 $6 &>> $LOG_FILE
stop_spinner $?

# Module 3: compute the test statistics
start_spinner ' - Running module 3  (computing test statistics)...'
$SCRIPTPATH/knockoffgwas/module_3_statistics.sh $1 $2 $3 $4 $5 $6 &>> $LOG_FILE
stop_spinner $?

# Module 4: report significant findings
start_spinner ' - Running module 4  (applying the knockoff filter)...'
$SCRIPTPATH/knockoffgwas/module_4_discover.sh $1 $2 $3 $4 $5 $6 &>> $LOG_FILE
stop_spinner $?

#####################
# Summarize results #
#####################

printf "\nResults written in 'results/'\n"
