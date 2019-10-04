#!/bin/sh
#SBATCH --time=00:15:00
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1

# the resources requested above must be within the allocation

# we need to load the julia module so that the paths are set up right.
module load swenv/default-env/devel
module load lang/Julia/1.1.1

# this starts the julia script which will srun its own processes
julia test_cm.jl
