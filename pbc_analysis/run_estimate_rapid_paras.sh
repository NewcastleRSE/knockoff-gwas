#Usage: python parameter_estimation <vcf_input_file> <error_rate> <num_haplotypes> <min_snps>,
# or\\ python parameter_estimation <vcf_input_file> <error_rate> <num_haplotypes> <min_snps> <num_run> <num_success>

#python parameter_estimation.py <vcf_input_file> <error_rate> <num_haplotypes> <min_snps>

python ../new_knockoffgwas_pipeline/knockoffgwas_pipeline/new_bits/parameter_estimation.py data/Nicola_chr$1.vcf.gz 0.0025 1000 49020 10 2

