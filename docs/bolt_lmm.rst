.. _bolt_lmm:

Step 3. BOLT-LMM Analysis
=========================

Comparison of the KnockOffGWAS results with a more traditional GWAS can be done with the use of `BOLT-LMM <https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html>`_.

Once BOLT-LMM is installed on your HPC machine (or elsewhere), the analysis can be run with the script called ``run_lmm.sh`` which has the following parameters. 

**Command-Line Parameters for run_lmm.sh**

    1. Start chromosome number.

    1. End chromosome number.

    3. Path and filename prefix of the data.

    4. The phenotype name to give to the phenotype data. 

    5. The directory name used to store the results. This directory will be created automatically by the pipeline.

    6. Linkage disequilibrium (LD) tables for BOLT-LMM. These should be appropriate for the data you are using. See `BOLT-LMM <https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html>`_ documentation for details.

    7. Genetic map table for BOLT-LMM. Again, these should be appropriate for the data you are using. See `BOLT-LMM <https://storage.googleapis.com/broad-alkesgroup-public/BOLT-LMM/BOLT-LMM_manual.html>`_ documentation for details.

Create an HPC script to do the preprocessing in the ``hpc`` directory called ``bolt-lmm.sh`` which should look something like the following:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=your_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=10GB
    #SBATCH --output=slurm_bolt_lmm_%a.out

    # Load modules
    module load BOLT-LMM
    module load PLINK/1.9b_6.21-x86_64
    module load R/4.5.1-gfbf-2024a 

    # Set dirs
    source ./set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC BOLT-LMM analysis"

    ../new_knockoffgwas_pipeline/run_lmm.sh 1 22 $DATA/mydata pbc results $DATA"/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz" $DATA"/tables/genetic_map_hg19_withX.txt.gz"

    date

As before, this will need to be updated for the requirements of the HPC machine that you are using. The script requires BCFTools, Plink version 1.9 and R, so these must be loaded.

The start and end chromosomes are set to 1 and 22.

The path and filename prefix of the data is given next by ``$DATA/mydata``. The data should be formatted as described in the previous section; see :ref:`initial_prep`.

The phenotype name is given next, which is set here to ``pbc`` for the Primary Biliary Cholangitis (PBC) dataset. 

The results directory is set to ``results``.

The linkage disequilibrium (LD) tables have been included as data download from the 1000 genomes project.

The genetic map tables have been downloaded in advance as appropriate for the PBC data we are using.

Run the analysis as an array job on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt-lmm.sh

or whatever is appropriate for the HPC machine you are using.

Results for the analysis will be stored in the ``results/lmm`` with a statistics file for chromosomes 1-22 named ``stats_chr1_chr22_lmm.txt`` along with two clumping files `clump_chr1_chr22_lmm_regions.txt` and `clump_chr1_chr22_lmm_clumped.tab`.

Run the analysis on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt-lmm.sh

or whatever is appropriate for the HPC machine you are using.

