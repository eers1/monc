#!/bin/bash
# Use the current working directory:
#$ -cwd
# Export variables:
#$ -V
# Request 36 cores:
#$ -pe ib 10
# Request 4G of memory per core:
#$ -l h_vmem=10G
# Request 270 minutes of run time:
#$ -l h_rt=00:10:00
#$ -l placement=scatter 

# NOTES:
#
# Make sure the walltime_limit setting in the MONC config file is less than
# the requested run time, e.g. setting the MONC walltime_limit to 10 hours
# and requesting 12 hours of run time should be safe.

# Display start time:
echo "START TIME: $(date)"

# --- Set up:

# Get job script name from queueing system variables:
export SUBMISSION_SCRIPT_NAME='monc_chain_job_rs.sh'

# Load required modules:
. /nobackup/cemac/cemac.sh
module purge
module load user
module switch intel gnu #/native
module switch openmpi mvapich2
module load netcdf hdf5 fftw fcm

# List loaded modules:
module list 2>& 1

if [ ! -d checkpoint_files ]; then mkdir checkpoint_files; fi
if [ ! -d monc_stdout ]; then mkdir monc_stdout; fi
if [ ! -d diagnostic_files ]; then mkdir diagnostic_files; fi

# MVAPICH2 variables:
MONC_THREAD_MULTIPLE=0
MV2_ENABLE_AFFINITY=0
MV2_SHOW_CPU_BINDING=1
MV2_USE_THREAD_WARNING=0
export MONC_THREAD_MULTIPLE MV2_ENABLE_AFFINITY MV2_SHOW_CPU_BINDING \
       MV2_USE_THREAD_WARNING
export OMP_NUM_THREADS=1


# Set the job config file:
export MONC_CONFIG='dycoms_mvapich.mcf'
# Path to MONC executable:
export MONC_EXEC='build/bin/monc_driver.exe'
# Standard output log file:
export MONC_OUT='monc.out'
# Get checkpoint file details from config file:
#CKPT_DIR=$(dirname $(grep '^checkpoint_file=' ${MONC_CONFIG} | \
#             awk -F '=' '{print $2}' | sed 's|"||g' | sed "s|'||g"))
export CP_DIR='checkpoint_files'
# --- Checks:

ulimit -c unlimited
# Check for run completion message in monc output file:
function check_complete() {
  if [ -r "${MONC_OUT}" ] ; then
    grep -q 'Model run complete due to model time' ${MONC_OUT} >& /dev/null
    if [ "${?}" = "0" ] ; then
      echo 'MONC run appears to have completed (exceeded termination time)'
      # Display end time:
      echo "END TIME: $(date)"
      exit 0
    fi
  fi
}
check_complete

# Check for previous checkpoint file:
if [ -r "${MONC_OUT}" ] ; then
  PREV_CKPT_FILE=$(basename $(grep \
                     'Restarted configuration from checkpoint file' \
                     ${MONC_OUT} | egrep -o '[0-9a-zA-Z_/-]+\.nc') \
                     2> /dev/null)
fi
# Check for most recent existing checkpoint file:
CKPT_FILE=$(basename $(\ls -1v ${CP_DIR} | tail -n 1) 2> /dev/null)
# If current chckpoint file is same as previous, give up:
if [ ! -z "${PREV_CKPT_FILE}" ] && [ ! -z "${CKPT_FILE}" ] ; then
  if [ "${PREV_CKPT_FILE}" = "${CKPT_FILE}" ] ; then
    echo "Previous checkpoint file is same as current (${CKPT_FILE})"
    # Display end time:
    echo "END TIME: $(date)"
    exit 1
  fi
fi

# If we have a checkpoint file, restart MONC, else, start from config:
if [ ! -z "${CKPT_FILE}" ] ; then
  MONC_ARGS="--checkpoint=${CP_DIR}/${CKPT_FILE}"
else
  MONC_ARGS="--config=${MONC_CONFIG}"
fi

# --- Run:
# Run!:
mpirun ${MONC_EXEC} ${MONC_ARGS} | tee ${MONC_OUT}

# --- Submit next job:

# Check if MONC run has finished:
check_complete

# Avoid job chaining bug on ARC systems:
export PATH=${SGE_O_PATH}
unset SGE_STARTER_PLUGINS
# Submit next job:
echo 'Submitting next job in chain ...'
qsub ${SUBMISSION_SCRIPT_NAME}

# Display end time:
echo "END TIME: $(date)"
