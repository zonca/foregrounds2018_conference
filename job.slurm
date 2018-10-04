#!/bin/bash

#SBATCH --partition=debug

#SBATCH --account=mp107
#SBATCH --nodes=10
#SBATCH --time=00:30:00
#SBATCH --job-name=fg2018
#SBATCH --output=out_tiny_satellite_edison_%j.log
#SBATCH --mail-type=ALL
#SBATCH --constraint=knl,quad,cache
#SBATCH --core-spec=4



set -o errexit
set -v



echo Starting slurm script at $(date)

echo -e "\n-----------------------------------------------------------------------"
echo -e "ENVIRONMENT:\n"
env | sort -d
echo -e "-----------------------------------------------------------------------\n"
echo "PYTHON: $(which python)"
echo "PYTHON VERSION: $(python --version &> /dev/stdout)"
echo ""

# This script assumes that you are running at NERSC and have already
# loaded the toast module for the correct machine / configuration.

# This should be the same as the --nodes option above
nodes=$SLURM_JOB_NUM_NODES

# How many processes are we running per node?  Handle
# the case of a very small simulation.
if [ $nodes -lt 20 ]; then
    node_proc=1
else
    node_proc=16
fi

# The executable script

ex=$(which toast_satellite_sim.py)
echo "Using ${ex}"

# Scan strategy parameters from a file

parfile="scanning.par"

# Observations

nobs=20

group_num_nodes=1
groupsize=$(( node_proc * group_num_nodes ))

madam="madam.par"
fpfile="fpfg2018_61.pkl"
outdir="out/fg2018_61pix_20d"

# The commandline

com="${ex} @${parfile} \
--toast-output-dir "${outdir}" \
--toast-timing-fname "timing_report_main" \
--groupsize ${groupsize} \
--madam \
--madampar ${madam} \
--fp ${fpfile} \
--numobs ${nobs} \
--outdir ${outdir}/out \
$@ \
"

#--- Hardware configuration ----

# Hyperthread CPUs per physical core
cpu_per_core=4

# Physical cores we are using
node_cores=64

node_thread=$(( node_cores / node_proc ))
node_depth=$(( cpu_per_core * node_thread ))
procs=$(( nodes * node_proc ))

export OMP_NUM_THREADS=${node_thread}
export OMP_PLACES=threads
export OMP_PROC_BIND=spread
export TOAST_NODE_COUNT=${nodes}
export TOAST_NUM_THREADS=${OMP_NUM_THREADS}
echo "OpenMP # threads: ${OMP_NUM_THREADS}"
echo "TOAST # threads: ${TOAST_NUM_THREADS}"

# Set TMPDIR to be on the ramdisk
export TMPDIR=/dev/shm

run="srun --cpu_bind=cores -n ${procs} -N ${nodes} -c ${node_depth}"

echo Calling srun at $(date)

: ${LOG_OUT:="${outdir}/log"}
echo "${run} ${com}"
eval ${run} ${com} > ${LOG_OUT} 2>&1

echo End slurm script at $(date)
