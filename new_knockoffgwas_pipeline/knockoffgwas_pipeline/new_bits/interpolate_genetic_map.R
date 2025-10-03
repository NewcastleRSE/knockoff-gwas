#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)
if(length(args) < 3) stop("Usage: script.R map.tsv file.bim out_map.tsv")

# Read files
map <- read.table(args[1], header=TRUE, sep="\t", stringsAsFactors=FALSE)
bim <- read.table(args[2], header=FALSE, stringsAsFactors=FALSE)
colnames(bim) <- c("CHR","SNP","MORG","BP","A1","A2")
colnames(map) <- c("CHR", "BP", "RATE", "CM")

head map

# Rate is cM/Mb

# Match positions
merged <- merge(bim, map, by.x=c("CHR","BP"), by.y=c("CHR","BP"), all.x=TRUE)

head merged

# Interpolate missing Map.cM
need_interp <- is.na(merged$CM)
if(any(need_interp)){
  interp_vals <- approx(x=map$BP, y=map$CM,
                        xout=merged$BP[need_interp], rule=2, ties=mean)$y
  merged$CM[need_interp] <- interp_vals
}

# Build output genetic map
out <- data.frame(merged$CHR,
                  merged$BP,
                  merged$RATE,
                  merged$CM)

head out

colnames(out)<-c("Chromosome", "Position(bp)", "Rate(cM/Mb)", "Map(cM)")

# Write
write.table(out, file=args[3], sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE)

