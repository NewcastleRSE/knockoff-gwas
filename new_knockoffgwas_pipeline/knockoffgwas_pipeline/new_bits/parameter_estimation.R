library(gzfile)
library(stats)
library(zoo)  # for rollapply
library(pracma)  # for factorial
library(utils)

w_rho_vals <- c()

compute_mafs <- function(vcf_input, max_window_size) {
  lines <- readLines(gzfile(vcf_input))
  entries_started <- FALSE
  mafs <- c()
  
  for (line in lines) {
    if (grepl("#CHROM", line)) {
      entries_started <- TRUE
      next
    }
    if (!entries_started) next
    
    vals <- strsplit(line, "\t")[[1]]
    pos <- vals[2]
    alt <- vals[5]
    if (grepl(",", alt)) next
    
    genotypes <- vals[10:length(vals)]
    num_ones <- 0
    num_zeros <- 0
    
    for (g in genotypes) {
      alleles <- unlist(strsplit(g, "[/|]"))
      for (a in alleles) {
        if (a == "1") num_ones <- num_ones + 1
        else if (a == "0") num_zeros <- num_zeros + 1
      }
    }
    
    total <- num_zeros + num_ones
    if (total > 0) {
      v <- min(num_zeros, num_ones) / total
      mafs <- c(mafs, v)
    }
  }
  
  x_vals <- c(0)
  y_vals <- c(0)
  
  for (window_size in 1:(max_window_size - 1)) {
    expected_vals <- c()
    for (i in seq(1, length(mafs), by = window_size)) {
      end_index <- min(i + window_size - 1, length(mafs))
      chunk <- mafs[i:end_index]
      sum_maf <- sum(chunk)
      expected_maf <- sum(ifelse(sum_maf > 0, (chunk^2) / sum_maf, 0))
      expected_vals <- c(expected_vals, expected_maf)
    }
    
    pa <- quantile(expected_vals, 0.01)
    rho_v <- pa^2 + (1 - pa)^2
    x_vals <- c(x_vals, window_size)
    y_vals <- c(y_vals, rho_v)
  }
  
  # Lowess smoothing
  smoothed <- lowess(x_vals, y_vals, f = 0.1)
  assign("w_rho_vals", smoothed$y, envir = .GlobalEnv)
}

ncr <- function(n, r) {
  factorial(n) / (factorial(r) * factorial(n - r))
}

w_rho_func <- function(w) {
  if (w >= length(w_rho_vals)) {
    return(w_rho_vals[length(w_rho_vals)])
  } else {
    return(w_rho_vals[as.integer(w)])
  }
}

fp <- function(e, N, L, rho, r, c, w) {
  sum_val <- 0
  for (i in 0:(c - 1)) {
    term <- ncr(r, i) * (rho^(L / w))^i * ((1 - rho^(L / w))^(r - i))
    sum_val <- sum_val + term
  }
  return(1 - sum_val)
}

tp <- function(er, N, L, rho, r, c, w) {
  sum_val <- 0
  for (i in 0:(c - 1)) {
    term <- ncr(r, i) * (exp(-(er * L) / w))^i * ((1 - exp(-(L * er) / w))^(r - i))
    sum_val <- sum_val + term
  }
  return(1 - sum_val)
}

compute_w <- function(error_rate, N, L, rho, r, c, max_w = 300) {
  lambda_val <- 0.5 * N * (N - 1)
  w_min <- -1
  started <- FALSE
  
  for (w in 1:max_w) {
    tp1 <- tp(error_rate, N, L, w_rho_func(w), r, c, w)
    fp1 <- fp(error_rate, N, L, w_rho_func(w), r, c, w)
    if (round(tp1, 2) - lambda_val * round(fp1, 2) == 1) {
      if (!started) {
        w_min <- w
        started <- TRUE
      }
    } else if (started) {
      cat(w_min, w, "\n")
      return(0)
    }
  }
  
  cat(w_min, max_w, "\n")
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  cat("Usage: Rscript parameter_estimation.R <vcf_input_file> <error_rate> <num_haplotypes> <min_snps>, or\n")
  cat("       Rscript parameter_estimation.R <vcf_input_file> <error_rate> <num_haplotypes> <min_snps> <num_run> <num_success>\n")
  quit(status = 1)
}

vcf_input <- args[1]                 # VCF input file
error_rate <- as.numeric(args[2])    # Error rate
num_haps <- as.integer(args[3])      # Number of haplotypes
min_length_SNPs <- as.integer(args[4]) # Minimum number of SNPs

num_runs <- 10
num_success <- 2

if (length(args) > 4) {
  num_runs <- as.integer(args[5])
  num_success <- as.integer(args[6])
}

max_window_size <- 300
rho_initial <- 0.9

compute_mafs(vcf_input, max_window_size)
compute_w(error_rate, num_haps, min_length_SNPs, rho_initial, num_runs, num_success, max_window_size)


