.. _container:

Pipeline Container
==================

🚧🚧 Under Construction 🚧🚧

In order to make the pipeline as portable as possible across computing environments an `Apptainer <https://apptainer.org/>`_ container is supplied. This section gives a brief description on how to use the container to analyse your data, and you should refer to the corresponding non-container sections for more details.

All of the scripts below will need to be amended for use with the HPC machine you are using and your individual details.

Setup
-----

Create a directory for your analysis and save in it a script called ``set_dirs.sh`` which creates a variable called ``DATA`` which points to your dataset. The file should look something as follows:

.. code-block:: none

    # Run this file using "source set_dirs.sh" to set the following variable
    DATA=/nobackup/proj/my_account/data

Download the apptainer container file `kogwas.sif <TBA>`_ and save it in your analysis directory or somewhere accessible.

Create an ``hpc`` directory to save scripts to run the data preparation and analysis.

.. code-block:: none

    mkdir hpc

See :ref:`initial_prep` on how your data should be formatted.

**Running scripts**

Running a pipeline script that is stored inside the container is not too much different from before. Instead of running scripts like this:

.. code-block:: none

    ../new_knockoffgwas_pipeline/run_lmm.sh 1 22 $DATA/mydata ...

they should be run like this:

.. code-block:: none

    apptainer exec --bind $DATA:/data kogwas.sif run_lmm.sh 1 22 /data/mydata ...

The ``$DATA`` variable should point to the location of your data on the host system. This path must be bind-mounted to the ``\data`` directory inside the container, since the scripts running in the container expect to find the data there.

The sub-sections below will take you through each step of using the pipeline with the container. As before, all scripts will need to be modified for your details and the requirements of the HPC machine that you are using. 

Data preprocessing
------------------

Firstly, some map files need to be created with script `hpc/pre_create_map_files.sh`:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=my_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=20GB
    #SBATCH --output=slurm_pre_create_map_files.out

    # Load modules
    module load apptainer

    #Set dirs
    source set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC pre-analysis creating map files using container"

    apptainer exec --bind $DATA:/data kogwas.sif run_pre_create_map_files.sh 1 22 /data/Nicola results /data/genetic_maps/genetic_map_GRCh37

    date

Run it with:

.. code-block:: none

    sbatch hpc/pre_create_map_files.sh

Note that just the apptainer module needs to be loaded instead of various packages which are now handled by the container.

Next the data needs to be phased and the IBD segments calculated with script `hpc/pre.sh`:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=my_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=20GB
    #SBATCH --array=1-22                       # Tasks to run, corresponds to chromosome number
    #SBATCH --output=slurm_pre_%a.out

    # Load modules
    module load apptainer

    #Set dirs
    source set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC pre-analysis data preparing using container"

    # Phase chromosome data
    apptainer exec --bind $DATA:/data kogwas.sif run_pre_phasing.sh $SLURM_ARRAY_TASK_ID /data/mydata pbc results

    # It may be necessary to change the segment length and window size until suitable IBD data is returned
    apptainer exec --bind $DATA:/data kogwas.sif run_pre_ibd.sh $SLURM_ARRAY_TASK_ID /data/mydata pbc results 25 3

    date

Run it with:

.. code-block:: none

    sbatch hpc/pre.sh

There may be some problems setting the segment length and window size, see :ref:`running_prep` for more details.

Analysis
--------

See :ref:`analysis` for more details on running the KnockOffGWAS analysis. To do so using the container create a script `hpc/analysis.sh` something similar to the following:

.. code-block:: none
        
    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=my_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=100GB
    #SBATCH --array=1-22                       # Run tasks for given chromosomes
    #SBATCH --output=slurm_anal_%a.out

    # Load modules
    module load apptainer

    # Set dirs
    source ./set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC analysis using container"

    apptainer exec --bind $DATA:/data kogwas.sif run_knockof_gwas.sh $SLURM_ARRAY_TASK_ID /data/mydata pbc 0.1 results

    date

and run it with:

.. code-block:: none

    sbatch hpc/analysis.sh

BOLT-LMM Analysis
-----------------

See :ref:`bolt_lmm` for further details. Create an HPC script to do the preprocessing in the ``hpc`` directory called ``cont_bolt_lmm.sh`` which should look something like the following:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=my_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=10GB
    #SBATCH --output=slurm_bolt_lmm.out

    # Load modules
    module load apptainer
    
    # Set dirs
    source ./set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC BOLT-LMM analysis using container"

    apptainer exec --bind $DATA:/data kogwas.sif run_lmm.sh 1 22 /data/mydata pbc lmm_results /data/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz /data/tables/genetic_map_hg19_withX.txt.gz

    date

As before, this will need to be updated for the requirements of the HPC machine that you are using. 

Run the analysis as an array job on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt_lmm.sh

or whatever is appropriate for the HPC machine you are using.

Results for the analysis will be stored in the ``results/lmm`` with a statistics file for chromosomes 1-22 named ``stats_chr1_chr22_lmm.txt`` along with two clumping files `clump_chr1_chr22_lmm_regions.txt` and `clump_chr1_chr22_lmm_clumped.tab`.

Run the analysis on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt_lmm.sh

or whatever is appropriate for the HPC machine you are using.

Removing temporary files
------------------------

A number of files are produced during the data preprocessing and during analysis calculations. These files can be removed by running a script, which also restores the `.fam` file which needed to have its format altered. If you remove the temporary files and wish to rerun the analysis for any reason you will need to rerun the data preprocessing scripts also.

The script, `run_remove_temporary_files.sh`, can be ran from the container as follows:

.. code-block:: none

    source set_dirs.sh
    apptainer exec --bind $DATA:/data kogwas.sif run_remove_temporary_files.sh /data/mydata

Where the parameter is the path and filename of the data used in the analysis.

Visualisation
-------------

The visualisation of the results should still be done without the container using the shiny R app, `app.R`, which can be found `here <https://github.com/NewcastleRSE/knockoff-gwas/tree/main/new_knockoffgwas_pipeline/knockoffgwas_pipeline/visualization>`_.

See :ref:`visualisation` for details.