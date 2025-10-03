#!/usr/bin/env Rscript

# interpolate_genetic_map.R
#
# Given a genetic map (with columns: Chromosome, Position(bp), Rate(cM/Mb), Map(cM))
# and a PLINK .bim file, produce a new genetic map that contains only the SNPs in
# the .bim file (in the same order). For any SNP positions not present in the
# input genetic map, the script interpolates (linearly) the Map(cM) value.
# Optionally, it recalculates Rates (cM/Mb) for the output SNPs using central
# differences.
#
# Usage:
#   Rscript interpolate_genetic_map.R --map map.tsv --bim file.bim --out out_map.tsv [--recalc-rate TRUE]
#
# Requirements: base R (no extra packages required).

suppressWarnings(suppressMessages({
  args <- commandArgs(trailingOnly = TRUE)
}))

# --- simple argument parsing ---
arg_value <- function(flag, default = NULL) {
  i <- which(args == flag)
  if (length(i) == 0) return(default)
  if (i == length(args)) stop(paste0("flag ", flag, " provided but no value"))
  return(args[i + 1])
}

map_file <- arg_value("--map")
bim_file <- arg_value("--bim")
out_file <- arg_value("--out", "map_from_bim.tsv")
recalc_rate <- tolower(arg_value("--recalc-rate", "true"))
if (recalc_rate %in% c("true", "t", "1")) recalc_rate <- TRUE else recalc_rate <- FALSE

if (is.null(map_file) || is.null(bim_file)) {
  cat("\nUsage: Rscript interpolate_genetic_map.R --map map.tsv --bim file.bim --out out_map.tsv [--recalc-rate TRUE]\n\n")
  quit(status = 1)
}

# --- read input files ---
# Map file: allow header or no header; we'll try to detect columns by names.
map_df <- tryCatch(
  read.table(map_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, comment.char = "", quote = "\""),
  error = function(e) {
    stop("Failed to read map file: ", e$message)
  }
)

# Normalize column names to simple forms
colnames(map_df) <- make.names(colnames(map_df))

# Expected columns: Chromosome, Position.bp., Rate.cM.Mb., Map.cM.  Accept variants.
find_col <- function(poss) {
  hits <- intersect(poss, colnames(map_df))
  if (length(hits)) return(hits[1])
  return(NULL)
}

chr_col <- find_col(c('Chromosome','chromosome','chr','CHR'))
pos_col <- find_col(c('Position.bp.','Position','Pos','position','bp'))
map_col <- find_col(c('Map.cM.','Map','cM','Map.cM','Map_cm','cM_map'))
rate_col <- find_col(c('Rate.cM.Mb.','Rate','Rate.cM.Mb','cM.Mb','cM.per.Mb','cM_Mb'))

if (is.null(chr_col) || is.null(pos_col) || is.null(map_col)) {
  stop('Map file must contain columns for chromosome, physical position (bp), and genetic map (cM).')
}

# Convert to expected names
map_df <- data.frame(
  Chromosome = as.character(map_df[[chr_col]]),
  Position.bp = as.numeric(map_df[[pos_col]]),
  Map.cM = as.numeric(map_df[[map_col]]),
  stringsAsFactors = FALSE
)
if (!is.null(rate_col)) map_df$Rate.cM.Mb <- as.numeric(map_df[[rate_col]])

# sort by chromosome then position
map_df <- map_df[order(map_df$Chromosome, map_df$Position.bp), ]
row.names(map_df) <- NULL

# Read BIM file (PLINK .bim): 6 columns, chr, snp, morg, bp, a1, a2
bim_df <- tryCatch(
  read.table(bim_file, header = FALSE, stringsAsFactors = FALSE),
  error = function(e) stop('Failed to read bim file: ', e$message)
)
if (ncol(bim_df) < 4) stop('bim file must have at least 4 columns (chr, snp, morg, bp)')
colnames(bim_df)[1:6] <- c('CHR','SNP','MORG','BP','A1','A2')

# We'll coerce chromosome formats to be comparable: e.g. 'chr22' vs '22'
clean_chr <- function(x) {
  x <- as.character(x)
  x <- sub('^chr', '', x, ignore.case = TRUE)
  return(x)
}

map_df$chr_clean <- clean_chr(map_df$Chromosome)
bim_df$chr_clean <- clean_chr(bim_df$CHR)

# We'll process chromosome by chromosome and interpolate Map(cM) at each BIM BP
out_rows <- list()

chromosomes <- unique(bim_df$chr_clean)
for (ch in chromosomes) {
  map_sub <- map_df[map_df$chr_clean == ch, c('Position.bp','Map.cM')]
  bim_sub <- bim_df[bim_df$chr_clean == ch, ]
  
  if (nrow(bim_sub) == 0) next
  
  if (nrow(map_sub) == 0) {
    warning(sprintf('No map entries found for chromosome %s. All Map(cM) values for this chromosome will be set to NA.', ch))
    interpolated_map <- rep(NA_real_, nrow(bim_sub))
  } else {
    # ensure unique increasing positions in map_sub
    keep <- !is.na(map_sub$Position.bp) & !is.na(map_sub$Map.cM)
    map_sub <- map_sub[keep, , drop = FALSE]
    if (nrow(map_sub) == 0) {
      warning(sprintf('Chromosome %s map has no usable entries. Setting NA.', ch))
      interpolated_map <- rep(NA_real_, nrow(bim_sub))
    } else {
      # remove duplicated positions (keep first)
      duppos <- duplicated(map_sub$Position.bp)
      if (any(duppos)) map_sub <- map_sub[!duppos, ]
      
      # linear interpolation/extrapolation using approx with rule=2 (linear extrapolation)
      # approx requires numeric x increasing
      ord <- order(map_sub$Position.bp)
      x <- map_sub$Position.bp[ord]
      y <- map_sub$Map.cM[ord]
      # approx will produce NA for NA inputs, so ensure bim positions are numeric
      query_x <- as.numeric(bim_sub$BP)
      # handle NA or missing BP
      interpolated_map <- approx(x = x, y = y, xout = query_x, rule = 2, ties = mean)$y
    }
  }
  
  out_sub <- data.frame(
    Chromosome = bim_sub$CHR,
    SNP = bim_sub$SNP,
    Position.bp = as.numeric(bim_sub$BP),
    Map.cM = interpolated_map,
    stringsAsFactors = FALSE
  )
  
  out_rows[[ch]] <- out_sub
}

# combine in the BIM order (preserve BIM file ordering)
all_out <- do.call(rbind, out_rows)
# reorder to match original bim order
bim_order_key <- paste0(bim_df$CHR, '|', bim_df$SNP, '|', bim_df$BP)
out_order_key <- paste0(all_out$Chromosome, '|', all_out$SNP, '|', all_out$Position.bp)
match_idx <- match(bim_order_key, out_order_key)
all_out <- all_out[match_idx, ]

# Recalculate Rate(cM/Mb) if requested
if (recalc_rate) {
  # We'll compute rate per SNP using central differences on Map.cM vs Position.bp.
  # rate[i] = (Map[i+1] - Map[i-1]) / (Pos[i+1] - Pos[i-1]) converted to cM/Mb
  n <- nrow(all_out)
  rate <- rep(NA_real_, n)
  pos <- all_out$Position.bp
  mapv <- all_out$Map.cM
  
  for (i in seq_len(n)) {
    if (is.na(mapv[i])) { rate[i] <- NA; next }
    if (i == 1) {
      # forward difference
      j <- which(!is.na(mapv) & seq_len(n) > i)
      if (length(j) == 0) { rate[i] <- NA; next }
      k <- j[1]
      dp <- pos[k] - pos[i]
      dm <- mapv[k] - mapv[i]
    } else if (i == n) {
      # backward difference
      j <- which(!is.na(mapv) & seq_len(n) < i)
      if (length(j) == 0) { rate[i] <- NA; next }
      k <- tail(j, 1)
      dp <- pos[i] - pos[k]
      dm <- mapv[i] - mapv[k]
    } else {
      # central using nearest non-missing neighbors
      j_prev <- tail(which(!is.na(mapv) & seq_len(n) < i), 1)
      j_next <- head(which(!is.na(mapv) & seq_len(n) > i), 1)
      if (length(j_prev) == 0 || length(j_next) == 0) {
        rate[i] <- NA; next
      }
      dp <- pos[j_next] - pos[j_prev]
      dm <- mapv[j_next] - mapv[j_prev]
    }
    if (is.na(dp) || dp == 0) { rate[i] <- NA } else {
      rate[i] <- (dm / (dp / 1e6)) # cM per Mb
    }
  }
  all_out$Rate.cM.Mb <- rate
}

# Final output columns: Chromosome, Position(bp), Rate(cM/Mb), Map(cM)
out_final <- data.frame(
  Chromosome = all_out$Chromosome,
  Position.bp = all_out$Position.bp,
  Rate.cM.Mb = all_out$Rate.cM.Mb,
  Map.cM = all_out$Map.cM,
  stringsAsFactors = FALSE
)

# write TSV
write.table(out_final, file = out_file, sep = "\t", quote = FALSE, row.names = FALSE)
cat(sprintf("Wrote output to %s\n", out_file))

# Print a small summary
cat(sprintf("Processed %d SNPs across %d chromosomes.\n", nrow(out_final), length(unique(bim_df$chr_clean))))

