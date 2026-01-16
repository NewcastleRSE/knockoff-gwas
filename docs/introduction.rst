.. _introduction:

Introduction
============

KnockoffGWAS is a powerful method for genome-wide association studies, Sesia et al. :cite:`sesia:etal:2021`,  that enables rigorous control of the false discovery rate while accounting for the complex correlation structure of genetic data. By constructing synthetic "knockoff" variants that closely mirror the dependencies of real genotypes, the method allows direct comparison between true and synthetic signals, substantially reducing false positives and improving the reliability of detected associations. Despite its strong theoretical foundations, applying KnockoffGWAS in practice has remained challenging due to strict data-format requirements, fragmented software dependencies, and the absence of a streamlined, end-to-end implementation.

This website provides a complete, practical solution. We present a fully automated pipeline that applies KnockoffGWAS starting from standard genetic data and genetic map files, handling all intermediate steps—from data preparation and format conversion to knockoff generation, inference, and final result interpretation. The workflow integrates multiple external tools, resolves compatibility issues, and standardises each step into a clear and reproducible process.

Using a large Primary Biliary Cholangitis (PBC) dataset as a real-world example, we demonstrate that KnockoffGWAS can be applied efficiently at scale. Our goal is to make this method accessible to a broader community by transforming a powerful but complex framework into a usable, transparent, and reproducible resource for genetic association studies.

|
|

Please follow the sections in the menu in order to perform a KnockOffGWAS analysis on your dataset.


