#!/usr/bin/env Rscript

# Converts RaPIDv1.7 format to RaPIDv1.2.3

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript convert_ibd_format.R <input_file> <output_file>\n")
}

infile  <- args[1]
outfile <- args[2]

# Read v1.7 file (space-delimited, no header)
df <- read.table(infile, header = FALSE, stringsAsFactors = FALSE)

# Assign column names based on v1.7 format
colnames(df) <- c(
  "CHR",
  "HAPID1",
  "HAPID2",
  "HID1",
  "HID2",
  "BP.start",
  "BP.end",
  "cM",
  "site.start",
  "site.end"
)

# Function to split HAPID into Family ID and Individual ID
# Splits from middle "_" so if individual and family IDs are different
# with a different number of "_" present then this will not be correct.
split_fam_ind <- function(hapid) {
  parts <- strsplit(hapid, "_")[[1]]
  mid <- floor(length(parts) / 2)
  fam <- paste(parts[1:mid], collapse = "_")
  ind <- paste(parts[(mid+1):length(parts)], collapse = "_")
  return(list(fam = fam, ind = ind))
}

# Extract FAM and ID for both haplotypes
fam1_id1 <- lapply(df$HAPID1, split_fam_ind)
fam2_id2 <- lapply(df$HAPID2, split_fam_ind)

FAM1 <- sapply(fam1_id1, function(x) x$fam)
ID1  <- sapply(fam1_id1, function(x) x$ind)

FAM2 <- sapply(fam2_id2, function(x) x$fam)
ID2  <- sapply(fam2_id2, function(x) x$ind)

# Build output in RaPID v1.2.3 format
out <- data.frame(
  CHR        = df$CHR,
  ID1        = ID1,
  HID1       = df$HID1,
  ID2        = ID2,
  HID2       = df$HID2,
  BP.start   = df$BP.start,
  BP.end     = df$BP.end,
  site.start = df$site.start,
  site.end   = df$site.end,
  cM         = df$cM,
  FAM1       = FAM1,
  FAM2       = FAM2,
  stringsAsFactors = FALSE
)

# Write result
write.table(out, outfile, sep = "\t", quote = FALSE, row.names = FALSE)