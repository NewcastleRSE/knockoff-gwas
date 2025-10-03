#!/usr/bin/env Rscript
#
# Richard Howey
# October 2025

# Input arguments
args <- commandArgs(trailingOnly=TRUE)
chr <- as.numeric(args[1])
geno.basename <- as.character(args[2])
phenotype.name <- as.character(args[3])

phenotype.filename<-paste0(geno.basename,"_phenotypes.txt")

cat("Creating phenotype file",phenotype.filename,"using .fam file from chromesome",chr, "with phenotype name",phenotype.name,"for use in KnockOffGWAS pipeline...\n")

all_snps<-c()
write_all<-FALSE

# Read in .fam file
fam.filename<-paste0(geno.basename,"_chr",chr,".fam")
fam<-read.table(fam.filename, header=FALSE)

# Create data to write to phenotype file
header=c("FID",	"IID", "sex", phenotype.name)
pheno.data<-fam[,c(1,2,5,6)]
colnames(pheno.data)<-header
  
# Write new phenotype name

write.table(pheno.data, phenotype.filename, row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t")
