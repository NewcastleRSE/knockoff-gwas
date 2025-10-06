#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)
if(length(args) < 3) stop("Usage: script.R map.tsv file.bim out_map.tsv")

# Read files
map <- read.table(args[1], header=TRUE, sep="\t", stringsAsFactors=FALSE)
bim <- read.table(args[2], header=FALSE, stringsAsFactors=FALSE) 
colnames(bim) <- c("CHR","SNP","MORG","BP","A1","A2")
colnames(map) <- c("CHR", "BP", "RATE", "CM")

# Rate is cM/Mb Match positions
merged <- merge(bim, map, by.x="BP", by.y="BP", all.x=TRUE)

# Interpolate missing Map.cM
need_interp <- is.na(merged$CM)

if(any(need_interp)){ interp_vals <- approx(x=map$BP, y=map$CM, xout=merged$BP[need_interp], rule=2, ties=mean)$y
  merged$CM[need_interp] <- interp_vals
}

# Estimate missing rates
need_rate <- which(is.na(merged$RATE))

# Loop thro' those with missing rates
for(i in need_rate) {
  if(i == 1){
    # If first position the use only first and second for estimate
    dm <- merged$CM[i+1] - merged$CM[i]
    dp <- merged$BP[i+1] - merged$BP[i]
  } else if(i == nrow(merged)){
    # If last position then only use last and second last positions
    dm <- merged$CM[i] - merged$CM[i-1]
    dp <- merged$BP[i] - merged$BP[i-1]
  } else {
    # Use surrounding positions
    dm <- merged$CM[i+1] - merged$CM[i-1]
    dp <- merged$BP[i+1] - merged$BP[i-1]
  }

 # Fill in missing rate value
 merged$RATE[i] <- ifelse(dp == 0, 0, dm / (dp / 1e6))
}

# Final genetic map data
out <- data.frame(merged$CHR.x, merged$BP, merged$RATE, merged$CM)
colnames(out)<-c("Chromosome", "Position(bp)", "Rate(cM/Mb)", "Map(cM)")

# Write
write.table(out, file=args[3], sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE)
