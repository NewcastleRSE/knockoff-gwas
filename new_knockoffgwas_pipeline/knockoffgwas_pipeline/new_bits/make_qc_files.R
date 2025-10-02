#!/usr/bin/env Rscript
#
# Richard Howey
# April 2025

# Input arguments
args <- commandArgs(trailingOnly=TRUE)
start.chr <- as.numeric(args[1])
end.chr <- as.numeric(args[2])
geno.basename <- as.character(args[3])
out.folder  <- as.character(args[4])

cat("Creating QC files using all SNP and individual data needed for KnockOffGWAS pipeline...\n")

all_snps<-c()
write_all<-FALSE

# Loop tho' the chrs and create QC files
for(chr in start.chr:end.chr)
{
    
    # Make a list of all SNPs 
    if(!file.exists(paste0(geno.basename,"_qc_chr", chr, ".txt")))
    {
      snps<-read.table(paste0(geno.basename, "_chr", chr, ".bim") ,header=FALSE)[,2]
      
      # Write list of all SNPs for this chr
      write.table(snps, paste0(geno.basename,"_qc_chr", chr, ".txt"), row.names=FALSE, col.names=FALSE, quote=FALSE)
      write_all<-TRUE
    } else {
      snps<-read.table(paste0(geno.basename,"_qc_chr", chr, ".txt"),header=FALSE)[,1]
    }
    
    all_snps<-append(all_snps, snps)  
}

# Write list of all SNPs for this chr
if(!file.exists(paste0(geno.basename,"_qc_variants.txt")) || write_all)
{
  write.table(all_snps, paste0(geno.basename,"_qc_variants.txt"), row.names=FALSE, col.names=FALSE, quote=FALSE)
}

# Write list of all SNPs if it does not exist or if any chrs have been updated
if(!file.exists(paste0(geno.basename,"_qc_samples.txt")) || write_all)
{
  # Read in family file
  fam<-read.table(paste0(geno.basename, "_chr", chr, ".fam"), header=FALSE)
  
  # Write list of all individuals
  write.table(fam[,1:2], paste0(geno.basename,"_qc_samples.txt"), row.names=FALSE, col.names=FALSE, quote=FALSE)
}    
