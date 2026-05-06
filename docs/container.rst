.. _container:

Pipeline Container
==================

🚧🚧 Under Construction 🚧🚧

In order to make the pipeline as portable as possible across computing environments an `Apptainer <https://apptainer.org/>`_ container is supplied. This section gives a brief description on how to use the container and you should refer to the other sections for more details of the data preparation and analysis.

Setup
-----

Create a directory for your analysis and save in it a script called ``set_dirs.sh`` which creates a variable called ``DATA`` which points to your dataset. The file should look something as follows:

.. code-block:: none

    # Run this file using "source set_dirs.sh" to set the following variable
    DATA=/nobackup/proj/your_account/data

Download the apptainer container file `kogwas.sif <TBA>`_ and save it in your analysis directory or somewhere accessible.

Create an ``hpc`` directory to save scripts to run the data preparation and analysis.

.. code-block:: none

    mkdir hpc

BOLT-LMM Analysis
-----------------

See :ref:`bolt_lmm` for further details. Create an HPC script to do the preprocessing in the ``hpc`` directory called ``cont-bolt-lmm.sh`` which should look something like the following:

.. code-block:: none

    #!/bin/bash
    #SBATCH --partition=default_free
    #SBATCH --account=your_account
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=10GB
    #SBATCH --output=app_bolt_lmm_%a.out

    # Set dirs
    source ./set_dirs.sh

    date
    echo "Running on $HOSTNAME PBC BOLT-LMM analysis using container"

    apptainer exec kogwas.sif run_lmm.sh 1 22 $DATA/mydata pbc results $DATA"/tables/LDSCORE.1000G_EUR.GRCh38.tab.gz" $DATA"/tables/genetic_map_hg19_withX.txt.gz"

    date

As before, this will need to be updated for the requirements of the HPC machine that you are using. 



Run the analysis as an array job on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt-lmm.sh

or whatever is appropriate for the HPC machine you are using.

Results for the analysis will be stored in the ``results/lmm`` with a statistics file for chromosomes 1-22 named ``stats_chr1_chr22_lmm.txt`` along with two clumping files `clump_chr1_chr22_lmm_regions.txt` and `clump_chr1_chr22_lmm_clumped.tab`.

Run the analysis on the HPC with the following command:

.. code-block:: none

    sbatch hpc/bolt-lmm.sh

or whatever is appropriate for the HPC machine you are using.
