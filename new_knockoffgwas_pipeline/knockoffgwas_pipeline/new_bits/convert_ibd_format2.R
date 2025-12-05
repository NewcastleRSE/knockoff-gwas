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

# Build output in RaPID v1.2.3 format
out <- data.frame(
  CHR        = df$CHR,
  ID1        = df$HAPID1,
  HID1       = df$HID1,
  ID2        = df$HAPID1,
  HID2       = df$HID2,
  BP.start   = df$BP.start,
  BP.end     = df$BP.end,
  site.start = df$site.start,
  site.end   = df$site.end,
  cM         = df$cM,
  FAM1       = rep(-1, dim(df)[1]),
  FAM2       = rep(-1, dim(df)[1]),
  stringsAsFactors = FALSE
)

# Write result
write.table(out, outfile, sep = "\t", quote = FALSE, row.names = FALSE)