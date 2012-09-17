#!/bin/bash
# Set up the script environment
source ../common.sh

# input directories
HISTO_SLICEDIR="$STACKINGDIR/volume/mask"
HISTO_SLICENAME="reslice_histo_mask"
MRI_INDIR="$DATADIR/input/mri_oriented"
MRI_INNAME="mri"
MRI_SLICEDIR="$DATADIR/input/mri_oriented_slices"
MRI_SLICENAME="mri_slice_"
HISTO_OUTDIR="$DATADIR/work/manual"

echo $DATA
