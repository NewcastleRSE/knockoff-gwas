args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  cat("Usage:\nRscript interpolate_loci.R <input_map_file> <vcf_input_gzip> <output_file>\n")
  quit(status = 1)
}

map_filepath <- args[1]
vcf_input <- args[2]
output_file <- args[3]

# Read VCF positions from gzipped file
con <- gzfile(vcf_input, "rt")
lines <- readLines(con)
close(con)

started <- FALSE
sites <- integer(0)

for (line in lines) {
  if (started) {
    vals <- strsplit(substr(line, 1, 1000), "\\s+")[[1]]
    sites <- c(sites, as.integer(vals[2]))
  } else if (grepl("#CHROM", substr(line, 1, 1000))) {
    started <- TRUE
  }
}

# Read map file
map_lines <- readLines(map_filepath)

xp <- integer(0)  # physical positions
yp <- numeric(0)  # genetic positions (cM)

for (line in map_lines) {
  vals <- strsplit(line, "\\s+")[[1]]
  xp <- c(xp, as.integer(vals[2]))
  yp <- c(yp, as.numeric(tail(vals, 1)))  # last column
}

# Perform interpolation
output_vals <- approx(x = xp, y = yp, xout = sites, rule = 2)$y

# Write output
out <- file(output_file, open = "wt")
for (i in seq_along(output_vals)) {
  writeLines(paste0(i - 1, "\t", output_vals[i]), out)
}
close(out)
