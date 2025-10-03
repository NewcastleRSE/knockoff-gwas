#!/bin/bash

# Needs run on finan to access the genetic map data

# Run interpolate_genetic_map.R for chromosomes 1-22

R_SCRIPT="../new_knockoffgwas_pipeline/knockoffgwas_pipeline/new_bits/make_phenotype_file_from_fam.R"

for CHR in $(seq 22 22); do
    MAP_FILE="../../genetic_maps/genetic_map_GRCh37_chr${CHR}.txt"
    BIM_FILE="data/Nicola_chr${CHR}.bim"
    OUT_FILE="data/Nicola_map_chr${CHR}.txt"

    if [[ ! -f "$MAP_FILE" ]]; then
        echo "Warning: $MAP_FILE not found, skipping chromosome $CHR"
        continue
    fi

    if [[ ! -f "$BIM_FILE" ]]; then
        echo "Warning: $BIM_FILE not found, skipping chromosome $CHR"
        continue
    fi

    echo "Processing chromosome $CHR ..."
    Rscript "$R_SCRIPT" --map "$MAP_FILE" --bim "$BIM_FILE" --out "$OUT_FILE" --recalc-rate TRUE
done

echo "All done!"