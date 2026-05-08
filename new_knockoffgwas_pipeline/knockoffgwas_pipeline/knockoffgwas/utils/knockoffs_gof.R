#!/usr/bin/env Rscript

# Load packages
suppressMessages(library(tidyverse))
suppressMessages(library(latex2exp))

# Default arguments (for debugging)
chr.name <- 21
res.name <- 1
stats.basename  <- "../../tmp/knockoffs_gof/knockoffs_chr21_res1"
groups.file <- "../../tmp/knockoffs/knockoffs_chr21_res1_grp.txt"
out.basename  <- "../../tmp/knockoffs_gof_plots/knockoffs_chr21_res1"

# Input arguments
args <- commandArgs(trailingOnly=TRUE)
chr.name <- as.character(args[1])
res.name <- as.character(args[2])
stats.basename  <- as.character(args[3])
groups.file <- as.character(args[4])
out.basename  <- as.character(args[5])


plot.knockoff.diagnostics <- function(chr.name, res.name, stats.basename, groups.file) {

    ## Load variable grouping
    Variants <- readr::read_delim(groups.file, delim=" ", progress = FALSE, col_types = readr::cols()) %>%
        dplyr::mutate(Group = as.integer(Group))

    ## Load variant frequency table
    frq.file <- sprintf("%s_self.frq", stats.basename)
    Frq <- readr::read_table(frq.file, col_types = readr::cols())

    ## Compute diagnostics
    Frq <- Frq %>%
        tidyr::separate(SNP, into = c("SNP", "Knockoff"), sep = "\\.k") %>%
        dplyr::mutate(Knockoff = ifelse(is.na(Knockoff), FALSE, TRUE))

    Diagnostics <- Frq %>%
        tidyr::pivot_wider(names_from="Knockoff", values_from=c("MAF")) %>%
        dplyr::mutate(x=`FALSE`, xk=`TRUE`) %>%
        dplyr::select(CHR, SNP, x, xk)

    ## Plot frequency diagnostics
    p.frq <- Diagnostics %>%
        ggplot2::ggplot(aes(x=x, y=xk)) +
        ggplot2::geom_point(alpha=0.2) +
        ggplot2::geom_abline(intercept = 0, slope = 1, color="red", linetype=2) +
        ggplot2::xlab(TeX("Allele-1 frequency ($X$)")) +
        ggplot2::ylab(TeX("Allele-1 frequency ($\\tilde{X}$)")) +
        ggplot2::xlim(0,1) +
        ggplot2::ylim(0,1) +
        ggplot2::theme_bw()

    ## Load LD table
    ld.file <- sprintf("%s.ld", stats.basename)
    LD <- suppressWarnings(readr::read_table(ld.file, col_types = readr::cols())) %>%
        dplyr::mutate(CHR=CHR_A) %>% dplyr::select(-CHR_A, -CHR_B)

    ## Add grouping information
    LD <- LD %>%
        dplyr::mutate(SNP=SNP_A) %>%
        dplyr::mutate(SNP = gsub(".k", "", SNP)) %>%
        dplyr::inner_join(Variants %>% dplyr::select(SNP, Group), by = c("SNP")) %>%
        dplyr::mutate(Group_A=Group) %>% dplyr::select(-SNP, -Group) %>%
        dplyr::mutate(SNP=SNP_B) %>%
        dplyr::mutate(SNP = gsub(".k", "", SNP)) %>%
        dplyr::inner_join(Variants %>% dplyr::select(SNP, Group), by = c("SNP")) %>%
        dplyr::mutate(Group_B=Group) %>% dplyr::select(-SNP, -Group)

    ## Add knockoff key information
    LD <- LD %>%
        tidyr::separate(SNP_A, into = c("SNP_A", "Knockoff_A"), sep = "\\.k") %>%
        dplyr::mutate(Knockoff_A = ifelse(is.na(Knockoff_A), FALSE, TRUE)) %>%
        tidyr::separate(SNP_B, into = c("SNP_B", "Knockoff_B"), sep = "\\.k") %>%
        dplyr::mutate(Knockoff_B = ifelse(is.na(Knockoff_B), FALSE, TRUE))

    ## Plot originality
    LD.cross <- dplyr::inner_join(LD.XX, LD.XkXk, by = c("Group_A", "Group_B", "SNP_A", "SNP_B"))
    p.orig <- LD.cross %>%
        dplyr::mutate(Distance = as.factor(abs(Group_A-Group_B))) %>%
        ggplot2::ggplot(aes(x=abs(R.XX), y=abs(R.XkXk))) +
        ggplot2::geom_abline(color="red") +
        ggplot2::geom_point(alpha=0.1) +
        ggplot2::xlim(0,1) +
        ggplot2::ylim(0,1) +
        ggplot2::xlab(TeX("|corr($X_{j},X_{k}$)|")) +
        ggplot2::ylab(TeX("|corr($\\tilde{X}_{j},\\tilde{X}_{k}$)|")) +
        ggplot2::theme_bw()

    ## Plot exchangeability
    options(repr.plot.width=4, repr.plot.height=3)
    LD.cross <- dplyr::inner_join(LD.XX, LD.XXk, by = c("Group_A", "Group_B", "SNP_A", "SNP_B")) %>%
        dplyr::filter(Group_A!=Group_B)

    p.exch <- LD.cross %>%
        dplyr::mutate(Distance = as.factor(abs(Group_A-Group_B))) %>%
        ggplot2::ggplot(aes(x=abs(R.XX), y=abs(R.XXk))) +
        ggplot2::geom_abline(color="red") +
        ggplot2::geom_point(alpha=0.1) +
        ggplot2::xlim(0,1) +
        ggplot2::ylim(0,1) +
        ggplot2::xlab(TeX("|corr($X_{j},X_{k}$)|")) +
        ggplot2::ylab(TeX("|corr($X_{j},\\tilde{X}_{k}$)|")) +
        ggplot2::theme_bw()

    ## Plot histogram of self-correlations
    p.self <- LD %>%
        dplyr::filter(BP_A==BP_B) %>%
        ggplot2::ggplot(aes(x=R2)) +
        ggplot2::geom_histogram(bins=30) +
        ggplot2::xlab(TeX("|corr($X_{j},\\tilde{X}_{j}$)|")) +
        ggplot2::theme_bw()

    ## Combine plots
    plot.title <- sprintf("Knockoff GOF for chromosome %s, resolution %s", chr.name, res.name)
    p.combined <- gridExtra::arrangeGrob(
        p.frq, p.orig, p.exch, p.self,
        nrow = 2,
        top = grid::textGrob(plot.title, gp = grid::gpar(fontsize=15, font=1))
    )

    return(p.combined)
}

## Make plot
pp <- plot.knockoff.diagnostics(chr.name, res.name, stats.basename, groups.file)

## Save plot
out.file <- sprintf("%s.png", out.basename)
ggplot2::ggsave(out.file, plot = pp)

cat(sprintf("GOF plots saved on %s\n", out.file))