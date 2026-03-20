.. _conclusions:

Conclusions
============

This pipeline has designed to be as automated and easy to use as possible. That said, there are a few possible difficulties:

1. During the data preparation stage the IBD segment length and window size must be set for use with RaPID to calculate the IBD segments. This may require some thought and rerunning of the IBD calculations, which is not ideal. If there are too many IBD segments the knockoff data may take too long to calculate.

1. The false discovery rate can be set to different values to calculate the final knockofGWAS results. While this is easy to set, it may require some thought.

1. Genetic map files must be supplied for the analysis which must be found.

1. The updated Shiny app makes it easy to view the results but interpretation may not be straightforward.

Hopefully this A fully automated pipeline makes KnockoffGWAS practical for real GWAS data. The workflow standardises knockoff generation, inference, and diagnostics. Application to PBC data shows scalable, FDR-controlled analysis is feasible.



