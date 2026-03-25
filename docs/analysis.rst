.. _analysis:

Step 2. Performing KnockOffGWAS
===============================

To perform KnockOffGWAS it is necessary that the data has been prepared as described in section :ref:`_prep`. 

You should have already have created a script called ``set_dirs.sh`` and saved it in your analysis directory. This script should look something like:

.. code-block:: none

    # Run this file using "source set_dirs.sh" to set the following variables
    DATA=/nobackup/proj/your_account/data

Next you should create an HPC script to do the analysis in the ``hpc`` directory called ``my_analysis.sh`` or something and should look something like the following:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=your_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=100GB
    #SBATCH --array=1-22                       # Run tasks for given chromosomes
    #SBATCH --output=slurm_anal_%a.out

    # Load modules

    module load BCFtools/1.22-GCC-13.3.0
    module load PLINK/1.9b_6.21-x86_64
    module load R/4.5.1-gfbf-2024a 

    # Set dirs
    source ./set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC analysis"

    ../new_knockoffgwas_pipeline/run_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/mydata pbc 0.1 results_d25_w3_FDR20

    date

As before, this will need to be updated for the requirements of the HPC machine that you are using. Important points to note about this script:

1. **Requirements**

   The script requires BCFTools, Plink version 1.9 and R, so these must be loaded.

2. **Command Parameters**

   Near the end of the script the ``run_knockoff_gwas.sh`` script is run with a number of parameters. These are the same parameters used with the data preparation script except the last two are omitted.

   a. The first two parameters are the minimum and maximum chromosomes. These are set to the same chromosome using the task job number given by ``$SLURM_ARRAY_TASK_ID``. The original example scripts allowed several chromosomes at once to be analysed, but in this new pipeline only one chromosome is processed at a time.

   b. The next parameter is the path and filename prefix of the data, ``$DATA/mydata``. The data should be formatted as described in the previous section; see :ref:`initial_prep`.

   c. The fourth parameter is the phenotype name to give to the phenotype data. In this case it is set to ``pbc`` for the Primary Biliary Cholangitis (PBC) dataset. This phenotype data should be initially stored in the sixth column of the ``.fam`` file. The necessary phenotype file for the pipeline will then be automatically created from this data.

   d. The fifth parameter is the false discovery rate (FDR), set to 0.1.

   e. The sixth parameter is the directory name used to store the results, here set to ``results``. This directory will be created automatically by the pipeline.


Run the analysis as an array job on the HPC with the following command:

.. code-block:: none

    sbatch hpc/my_analysis.sh

or whatever is appropriate for the HPC machine you are using.

Results for the analysis will be stored in the ``results`` with a statistics file for each chromosome 1-22 and seven different resolutions 0-6, for example: ``results_chr1_chr1_res0_stats.txt``. There are also accompanying files for regions passing the FDR criteria, set to 10% above, for example: ``results_chr1_chr1_res0_discoveries.txt``.

Goodness of fit plots (PNG files) are created and stored in ``results/knockoffs_gof_plots``.

Removing temporary files
------------------------

A number of files are produced during the data preprocessing and during analysis calculations. These files can be removed by running a script, which also restores the `.fam` file which needed to have its format altered. If you remove the temporary files and wish to rerun the analysis for any reason you will need to rerun the data preprocessing scripts also.

The script, `run_remove_temporary_files.sh`, can be ran as follows:

.. code-block:: none

    source set_dirs.sh
    ../new_knockoffgwas_pipeline/run_remove_temporary_files.sh 1 22 $DATA/mydata

Where the parameters are the start and end chromosome and the path and filename of the data used in the analysis.


