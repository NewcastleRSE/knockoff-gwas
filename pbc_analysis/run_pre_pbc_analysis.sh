# Create phenotype from fam file
Rscript --vanilla "../new_knockoffgwas_pipeline/knockoffgwas_pipeline/new_bits/make_phenotype_file_from_fam.R" 21 data/Nicola pbc

# Run the PBC dataset with one simple script called from anywhere, see script for parameters
../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh 21 22 data/Nicola y 0.1 results
