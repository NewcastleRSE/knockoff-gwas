#!/usr/bin/env Rscript
#
# Richard Howey
# April 2025

# Input arguments
args <- commandArgs(trailingOnly=TRUE)
input_file <- as.character(args[1])
output_file  <- as.character(args[2])


# Read in plink ped file
fam<-read.table(input_file, header=FALSE)

child_ID<-paste0(fam[,1],"_",fam[,2])      
father_ID<-paste0(fam[,1],"_",fam[,3])
mother_ID<-paste0(fam[,1],"_",fam[,4])
 
#
#(kidID fatherID and motherID), separated by TABs for spaces.

new_ped<-cbind(child_ID, father_ID, mother_ID)

# Write for use with Shapeit5
write.table(new_ped, output_file, row.names=FALSE, col.names=FALSE, quote=FALSE, sep="\t")
