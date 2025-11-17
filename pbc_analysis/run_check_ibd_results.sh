source set_dirs_comet.sh

CHR=21

gzip -dc $DATA/"Nicola_chr"$CHR".vcf.gz" | head
grep "^10" $DATA/"Nicola_map_rapid_chr"$CHR".txt" | head

../new_knockoffgwas_pipeline/knockoffgwas_pipeline/new_bits/RaPID_v.1.7 -i $DATA/"Nicola_chr"$CHR".vcf.gz" -m $DATA/"Nicola_map_rapid_chr"$CHR".txt" -o check_ibd_chr$CHR.ibd

