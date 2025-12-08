#!/usr/bin/env Rscript

# Converts .sample file format for Oxford .bgen format to sample file where the family and individual ID are the same
# after splitting the individual ID in two.

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript convert_sample_format.R <input_file> <output_file>\n")
}

infile  <- args[1]
outfile <- args[2]

# Read .sample file
df <- read.table(infile, header = TRUE, stringsAsFactors = FALSE)

# Function to split Individual ID into Family ID and Individual ID
# Splits from middle "_" so if individual and family IDs are different
# with a different number of "_" present then this will not be correct.
split_fam_ind <- function(hapid) {
  parts <- strsplit(hapid, "_")[[1]]
  mid <- floor(length(parts) / 2)
  fam <- paste(parts[1:mid], collapse = "_")
  ind <- paste(parts[(mid+1):length(parts)], collapse = "_")
  return(list(fam = fam, ind = ind))
}

# Extract FAM and ID
fam_id <- lapply(df[,2], split_fam_ind)

FAM <- sapply(fam_id, function(x) x$fam)
ID  <- sapply(fam_id, function(x) x$ind)

df[,1]<-FAM
df[,2]<-ID

# Write result
write.table(df, outfile, sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE)
