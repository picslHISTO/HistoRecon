# Set up the script environment
#!/bin/bash

# Define some functions to use in scripts
# 1. A function that waits until all submitted jobs have finished
function qblock() 
{
  echo "Waiting for all jobs to finish"
  while [ -n "`qstat -u $USER`" ]
  do
    sleep 5
  done
  echo "All jobs have finished executing!"
}

# ------------------------------------------ PARAMTERS
# histo raw data input directory 
HISTO_RAWDIR="/home/liuyang/data/Histo/Rob/1034"
HISTOMASK_RAWDIR="/home/liuyang/data/Histo/Rob/1034-mask"

# histo resize ratio
HISTO_RESIZE_RATIO=5%

# current dataset
sample="F"

# obsolete
# zoom factor of low and high resolution histology
# LOWRESZOOM=0.01
# HIRESZOOM=0.05

# Histology Orientation information
# NOTE: if the you don't want to flip, then HISTO_FLIP=""
HISTO_FLIP="yz"
HISTO_ORIENT="xzy"

# Voxel dimensions of the high resolution histology images
HIHSPACEX=0.000504
HIHSPACEY=0.000504
HIHSPACEZ=0.165

# Voxel dimensions of the low resolution histology images
HSPACEX=0.0108
HSPACEY=0.0108
HSPACEZ=0.165

# percent of pixels to pad histology images on all sides
# (to prevent going out of field of view during registration)
HISTO_PAD_PERCENT=30
# NOTE: padding the histology images introduces an edge, so we should only do it if they are masked
# before registration

# threshold used for creating histology of masks
MASK_HISTO_THRESH=0.56
# note should be variable with slice

# number of neighbouring slices that each histology slice is registered to during reconstruction step
LINEAR_RECON_SEARCH_RANGE=5

# flag for using ANTS or FSL for inter-slice registration during histology reconstruction
# (0 = ANTS linear, 1 = ANTS deformable, 2 = FSL linear)
LINEAR_RECON_ANTS=0

# inter-slice registration transformation used during histology reconstruction (no. DOF=3,5,6)
LINEAR_RECON_TRANS=3

# Number of slices to pad the histology volume at the front and back
NUMPAD=3

# number of iterations for histology-MRI matching
H2M_NITER=2

# flag for using ANTS or FSL for 3D MRI to histology registration
# (0 = FSL affine, 1 = ANTS affine, 2 = ANTS deform)
M2H_USE_ANTS=1

# flag for using deformable or affine registration of histology to mri slices
H2M_DEFORMABLE=0

# number of deformable histology iterations to run
DEFORM_NITER=4

# ------------------------------------------ PARAMTERS

BASEDIR=/home/liuyang/mouse12
ANTSDIR=/home/songgang/project/ANTS/gccrel-st-noFFTW
C3DDIR=/home/liuyang/bin/bin
FSLDIR=/home/avants/bin/fsl/fsl-4.1.0_32bit/bin
SCHDIR=/home/avants/bin/fsl/fsl-4.1.0_32bit/etc/flirtsch
MAGICKDIR=/home/liuyang/bin/ImageMagick/bin

SCRIPTDIR=$BASEDIR/scripts
PROGDIR=$BASEDIR/progs/bin
LD_LIBRARY_PATH=$BASEDIROLD/progs/itkbin:$LD_LIBRARY_PATH

PATH=$LD_LIBRARY_PATH:$AIRDIR:$ANTSDIR:$C3DDIR:$FSLDIR:$PROGDIR:$SCRIPTDIR:$PATH

FSLOUTPUTTYPE=NIFTI_GZ
export FSLOUTPUTTYPE


# Set up the directories used in all scripts
# Depending on whether we want to test or not, select the right directory tree

# Data directory
DATADIR=$BASEDIR/data

# MRI template directory
MRI_INDIR="$DATADIR/input/mri"
MRI_INNAME="canon_T1_r_halfsize_origin000_masked"
MRILABEL_INDIR="$DATADIR/input/mri"
MRILABEL_INNAME="waxholm_label_halfsize_origin000"

# Directory for temporary results
TMPDIR="$BASEDIR/tmp/${PPID}"
mkdir -p $TMPDIR

# Directory for qsub output
OUTPUTDIR="$BASEDIR/output"
ERRORDIR="$BASEDIR/error"
mkdir -p $OUTPUTDIR
mkdir -p $ERRORDIR

# Directory where the input images are located
# RAWDIR=$DATADIR/input/histo/raw
# mkdir -p $RAWDIR

# Directory where some parameter files are stored
PARMDIR=$BASEDIR/data/parameters
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

# Directory where the defomably warped mri slices are produced
DEFORMDIR=$DATADIR/work/deform
mkdir -p $DEFORMDIR

# Directory for getting the warp back the label 
LABELDIR=$DATADIR/work/label_to_orig
mkdir -p $LABELDIR

export LD_LIBRARY_PATH PATH RAWDIR MASKDIR GRAYDIR STACKINGDIR MODEL
export PARMDIR TMPDIR OUTPUTDIR ERRORDIR

