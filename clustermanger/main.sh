#!/usr/bin/sh

# start an allocation with 4 nodes 2 cpus per node and run the sbatch script which will start multiple julia process in a Julia Cluster.
salloc --nodes=4 --cpus-per-task 2 | sbatch julia.sbatch
