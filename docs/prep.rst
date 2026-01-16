.. _prep:

Step 1. File Preparation
========================

Before KnockOffGWAS can be performed there are many additional data files that are required. This section describes how to create these additional files.

.. _initial_prep:

Initial data preparation
------------------------

To use the use the pipeline your data must be given in `binary <https://zzz.bwh.harvard.edu/plink/binary.shtml>`_ PLINK format as a ``.bed`` file with corresponding ``.bim`` and ``.fam`` files, see :cite:`purcell:etal:07`. A text PLINK pedigree file, ``.ped``, with corresponding map file, ``.map``, may be used to create a binary file using PLINK as follows:

.. code-block:: none

  plink --noweb --file mydata --make-bed --out myfile

This will create the binary pedigree file, ``myfile.bed``, map file, ``myfile.bim``, and family file, ``myfile.fam`` required.

|

Furthermore, to use this pipeline the files need to be separated by chromosome and be named ``<some_name>_chr<number>.bed`` so that they can be processed. Thus your files should look something like the following:

.. code-block:: none

    mydata_chr1.bed
    mydata_chr1.bim
    mydata_chr1.fam
    mydata_chr2.bed
    mydata_chr2.bim
    mydata_chr2.fam
    ...
    mydata_chr22.bed
    mydata_chr22.bim
    mydata_chr22.fam

Quality Control of Data
-----------------------

The pipeline will not perform any kind of quality control on the data, so this needs to be done by yourself and is not in the scope of this project.

Setup directories for analysis
------------------------------

1. Download the pipeline, see :ref:`downloads`.
1. Create a directory for your analysis on the same level as the ``new_knockoffgwas_pipeline`` directory, i.e. below the ``knockoff_gwas`` directory. (You could create it elsewhere and change the HPC script appropriately to run the pipeline scripts.) 
1. Create an ``hpc`` directory to store HPC scripts in.

.. _running_prep:

Running data preprocessing
--------------------------

**Important** Create a script called ``set_dirs.sh`` and save it in your analysis directory. This script should define Bash variables ``DATA`` and ``IBD_DATA`` to point the directory where your data is stored and where IBD data should be stored. These files may be too big to store in your personal quota on an HPC machine so may need to be stored elsewhere which is still accessible when preprocessing and analysis is performed. For example, the file may be as follows:

.. code-block:: none

    # Run this file using "source set_dirs.sh" to set the following variables
    DATA=/nobackup/proj/your_account/data
    IBD_DATA=/nobackup/proj/your_account/ibd_data

Create an HPC script to do the preprocessing in the ``hpc`` directory called ``pre.sh`` which should look something like the following:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=your_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=20GB
    #SBATCH --array=1-22                       # Tasks to run, corresponds to chromosome number
    #SBATCH --output=slurm_pre_%a.out

    # Load modules

    module load BCFtools/1.22-GCC-13.3.0
    module load PLINK/1.9b_6.21-x86_64
    module load R/4.5.1-gfbf-2024a
    module load plink/2.0.0

    #Set dirs
    source set_dirs.sh

    date
    echo "Running on $HOSTNAME pre-analysis data preparing"

    # Run different chromosomes with different window sizes to get reasonable number of IBDs returned

    # Try different window sizes for chromosomes here until a suitable size is found
    ../new_knockoffgwas_pipeline/run_pre_knockoff_gwas.sh $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID $DATA/mydata pbc 0.1 results 10 3

    echo "Node memory state: `free`"
    date

This will need to be updated for the requirements of the HPC machine that you are using. Important points to note about this script:

1. **Requirements** The script requires BCFTools, Plink version 1.9 and Plink version 2 and R, so these must be loaded.
2. **Command Parameters** Near the end of the script the ``run_pre_knockoff_gwas.sh`` script is ran with a number of parameters. These parameters are...



Run the preprocessing as an arrary job on the HPC with the following command:

.. code-block:: none

    sbatch hpc/pre.sh

or whatever is appropriate for the HPC machine you are using.
