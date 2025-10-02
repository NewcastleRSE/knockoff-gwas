#!/usr/bin/env Rscript
#
# Richard Howey
# May 2025

# Input arguments
args <- commandArgs(trailingOnly=TRUE)
input_ibd_file <- as.character(args[1])
input_fam_file <- as.character(args[2])
output_file  <- as.character(args[3])

# Columns given in example IBD data
# CHR ID1 HID1 ID2 HID2 BP.start BP.end site.start site.end cM FAM1 FAM2

# Filter out individuals not in the same family


