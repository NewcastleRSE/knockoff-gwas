#!/bin/bash

source set_dirs.sh

# Parse clumped p-values and summarise discoveries all together
# Put all chr1_gwas.assoc.* in one file
# Put all gwas_clump_chr1.* in one file

CHR_MIN=1
CHR_MAX=22

# Output directory
OUT_DIR="results_gwas"

STATS_FILE=${OUT_DIR}/stats_chr${CHR_MIN}_chr${CHR_MAX}_lmm.txt
CLUMP_FILE=${OUT_DIR}/clump_chr${CHR_MIN}_chr${CHR_MAX}.tab

OUT_FILE=${OUT_DIR}/clump_chr${CHR_MIN}_chr${CHR_MAX}_lmm_regions.txt

STATS_FILE=${OUT_DIR}/stats_chr${CHR_MIN}_chr${CHR_MAX}_lmm.txt
CLUMP_FILE=${OUT_DIR}/clump_chr${CHR_MIN}_chr${CHR_MAX}.tab

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
SCRIPTPATH=$(dirname "$SCRIPT")

# Remove output files if they already exist
rm -f "$STATS_FILE" "$CLUMP_FILE"

first_stats=1
first_clump=1

for CHR in $(seq $CHR_MIN $CHR_MAX); do

stats_in=${OUT_DIR}/gwas_chr${CHR}.assoc.logistic
clump_in=${OUT_DIR}/gwas_clump_chr${CHR}.clumped
  
# ---- Combine GWAS stats ----
if [ -f "$stats_in" ]; then
if [ $first_stats -eq 1 ]; then
cat "$stats_in" >> "$STATS_FILE"
first_stats=0
else
  tail -n +2 "$stats_in" >> "$STATS_FILE"
fi
fi

# ---- Combine clump files ----
for f in $clump_in; do
if [ -f "$f" ]; then
if [ $first_clump -eq 1 ]; then
cat "$f" >> "$CLUMP_FILE"
first_clump=0
else
  tail -n +2 "$f" >> "$CLUMP_FILE"
fi
fi
done

done

# Summarise files
Rscript --vanilla $SCRIPTPATH/summarise_lmm.R ${CLUMP_FILE} ${OUT_FILE} $1 ${STATS_FILE} 1

# Get rid of temp files
rm ${CLUMP_FILE}
rm ${STATS_FILE}

