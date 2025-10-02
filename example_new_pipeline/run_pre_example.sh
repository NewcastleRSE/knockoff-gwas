# Put in some SNP names, example data did not have SNP allele names, just 0 and 0 which are the same! So conversion to vcf failed
sed -i -e 's/\t0\t0/\tT\tG/g' example_chr21.bim
sed -i -e 's/\t0\t0/\tT\tG/g' example_chr22.bim

# Run the example dataset with one simple script called from anywhere
../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh 21 22 example y 0.1 results
