#!/usr/bin/env Rscript

# Converts .fam file format to simple count of individuals for family and individual IDs

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript convert_fam_format.R <input_file> <output_file>\n")
}

infile  <- args[1]
outfile <- args[2]

# Read .fam file
df <- read.table(infile, header = FALSE, stringsAsFactors = FALSE)


df[,1]<-1:length(df[,1])
df[,2]<-1:length(df[,1])

# Write result
write.table(df, outfile, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
