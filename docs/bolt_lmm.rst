.. _bolt_lmm:

Step 3. BOLT-LMM Analysis
=========================

Comparison of the KnockOffGWAS results with a more traditional GWAS can be done with the use of `BOLT-LMM <https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html>`_.

Once BOLT-LMM is installed on your HPC machine (or elsewhere), it can be ran 

Create an HPC script to do the preprocessing in the ``hpc`` directory called ``bolt-lmm.sh`` which should look something like the following:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=your_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=10GB
    #SBATCH --output=slurm_bolt_lmm_%a.out

    MIN_CHR=1
    MAX_CHR=22

    # Load modules
    module load BOLT-LMM
    module load PLINK/1.9b_6.21-x86_64
    module load R/4.5.1-gfbf-2024a 

    # Set dirs
    source ./set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC analysis"

    ../new_knockoffgwas_pipeline/run_lmm.sh ${MIN_CHR} ${MAX_CHR} $DATA/mydata pbc 0.1 results $DATA"/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz" $DATA"/tables/genetic_map_hg19_withX.txt.gz"

    date


As before, this will need to be updated for the requirements of the HPC machine that you are using. Important points to note about this script:

1. **Requirements**

   The script requires BCFTools, Plink version 1.9 and R, so these must be loaded.

2. **Command Parameters**

   Near the end of the script the ``run_lmm.sh`` script is run with a number of parameters. 

   a. The first two parameters are the minimum and maximum chromosomes. These are set to calculate results for the whole genome.

   b. The next parameter is the path and filename prefix of the data, ``$DATA/mydata``. The data should be formatted as described in the previous section; see :ref:`initial_prep`.

   c. The fourth parameter is the phenotype name to give to the phenotype data. In this case it is set to ``pbc`` for the Primary Biliary Cholangitis (PBC) dataset. This phenotype data should be initially stored in the sixth column of the ``.fam`` file. The necessary phenotype file for the pipeline will then be automatically created from this data.

   d. The fifth parameter is the false discovery rate (FDR), set to 0.1. It has no purpose here but is included for consistency.

   e. The sixth parameter is the directory name used to store the results, here set to ``results``. This directory will be created automatically by the pipeline.

   f. The seventh parameter is a file for linkage disequilibrium (LD) tables for BOLT-LMM. These should be appropriate for the data you are using. See `BOLT-LMM <https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html>`_ documentation for details.

   g. The eighth parameter is a file for a genetic map table for BOLT-LMM. Again, these should be appropriate for the data you are using. See `BOLT-LMM <https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html>`_ documentation for details.


Run the analysis on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt-lmm.sh

or whatever is appropriate for the HPC machine you are using.

