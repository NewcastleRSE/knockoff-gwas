args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  cat("Usage:\nRscript filter_mapping_file.R <input_map_file> <output_file>\n")
  quit(status = 1)
}

input_file <- args[1]
output_file <- args[2]

# Read the input file
lines <- readLines(input_file)
header <- grep("Position", lines)
if (length(header) > 0) {
  lines <- lines[-header]
}

# Parse positions and check for duplicates
positions <- integer(length(lines))
pos_set <- integer(0)

for (i in seq_along(lines)) {
  vals <- strsplit(lines[i], "\\s+")[[1]]
  pos <- as.integer(vals[2])
  if (pos %in% pos_set) {
    cat("duplicate positions in the file\t", pos, "\n")
    quit(status = 1)
  }
  positions[i] <- pos
  pos_set <- c(pos_set, pos)
}

# Function to compute Longest Increasing Subsequence
LIS <- function(X) {
  n <- length(X)
  M <- integer(n + 1)
  P <- integer(n + 1)
  L <- 0
  
  for (i in seq_len(n)) {
    lo <- 1
    hi <- L
    while (lo <= hi) {
      mid <- floor((lo + hi) / 2)
      if (X[M[mid]] < X[i]) {
        lo <- mid + 1
      } else {
        hi <- mid - 1
      }
    }
    newL <- lo
    P[i] <- if (newL > 1) M[newL - 1] else 0
    M[newL] <- i
    if (newL > L) {
      L <- newL
    }
  }
  
  result <- integer(L)
  k <- M[L]
  for (i in L:1) {
    result[i] <- X[k]
    k <- P[k]
  }
  return(result)
}

# Get LIS of positions
lis_positions <- LIS(positions)
lis_set <- as.integer(lis_positions)

# Write output file
out <- file(output_file, open = "wt")
for (line in lines) {
  vals <- strsplit(line, "\\s+")[[1]]
  pos <- as.integer(vals[2])
  if (pos %in% lis_set) {
    writeLines(line, out)
  }
}
close(out)