# Set up the script environment
#!/bin/bash

# Define some functions to use in scripts
# 1. A function that waits until all submitted jobs have finished
function qblock 
{
  # get the qsub job names
  qname=$1
  if [[ $DO_QSUB == "Y" ]]; then
    echo "Waiting for all jobs to finish..."
    qsub -N "wait-$qname" -e $ERRORDIR -o $OUTPUTDIR -hold_jid "${qname}*" -sync y -b y echo ""
    echo "All jobs have been finished!"
  else
    echo "$1" has been finished
  fi
}

# A function execute the script with qsub or bash
function exe
{
  # exe qsub_jobname num_slots
  # num_slots = the amount of memory you need for each job
  qname=$1
  pe=$2
  shift 2
  # get whether to do the qsub or not
  if [[ $DO_QSUB == "Y" ]]; then 
    qsub -N ${qname} -pe serial ${pe} -o $OUTPUTDIR -e $ERRORDIR $*
  else
    bash $*
  fi
}

SCHDIR=$FSLDIR/../etc/flirtsch
FSLOUTPUTTYPE=NIFTI_GZ
export FSLOUTPUTTYPE

# Set up the directories used in all scripts
# Depending on whether we want to test or not, select the right directory tree

# Script directory
SCRIPTDIR=$BASEDIR/scripts

# Data directory
DATADIR=$BASEDIR/data
mkdir -p $DATADIR

# Directory for temporary results
TMPDIR="$BASEDIR/tmp/${PPID}"
mkdir -p $TMPDIR

# Directory for qsub output
OUTPUTDIR="$BASEDIR/output"
ERRORDIR="$BASEDIR/error"
mkdir -p $OUTPUTDIR
mkdir -p $ERRORDIR

# Directory where some parameter files are stored
PARMDIR=$DATADIR/parameters
mkdir -p $PARMDIR

# Directory where the non-padded nifti images are placed 
NIFTIDIR=$DATADIR/input/histo/nii
mkdir -p $NIFTIDIR

# Directory where the grayscale images are placed before registration
GRAYDIR=$DATADIR/input/histo/nii_padded
mkdir -p $GRAYDIR

# Directory where the mask images are placed
MASKDIR=$DATADIR/input/histo/nii_padded/mask
mkdir -p $MASKDIR

# Directory where the stacking of the histology data is placed
STACKINGDIR=$DATADIR/work/stacking
mkdir -p $STACKINGDIR

# Directory where the mri volume warped to histology is produced 
M2HDIR=$DATADIR/work/mri_to_histo
mkdir -p $M2HDIR

# Directory where the histology slices warped to mri are produced
H2MDIR=$DATADIR/work/histo_to_mri
mkdir -p $H2MDIR

# Directory where the the histolgoy slices are warped to the mri (the indices are manually matched)
MANUALDIR=$DATADIR/work/manual
mkdir -p $MANUALDIR

# Directory where the defomably warped mri slices are produced
DEFORMDIR=$DATADIR/work/deform
mkdir -p $DEFORMDIR

# Directory for getting the warp back the label 
LABELDIR=$DATADIR/work/label_to_orig
mkdir -p $LABELDIR

