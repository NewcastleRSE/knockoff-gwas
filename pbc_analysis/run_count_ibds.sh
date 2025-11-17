# Count number of haplotype segments in IBD result files

#Set dirs 
source set_dirs_comet.sh

# List of chromosomes
CHR_LIST=$(seq 1 22)

for CHR in $CHR_LIST; do

if [ -e $DATA"/Nicola_ibd_chr"$CHR".txt" ]; then
    w=$(wc -l < ${DATA}"/Nicola_ibd_chr"${CHR}".txt")
    echo Chromosome $CHR has this many IBD segments: $w
fi

done

