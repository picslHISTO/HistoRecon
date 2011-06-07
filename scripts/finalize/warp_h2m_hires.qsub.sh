#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh
source ../common.sh

# Read command line parameters
kpad=$1
h2m_tx=$2

$ANTSDIR/WarpImageMultiTransform 2 "$FINALDIR/linear/volume/slices/orig/reslice_histo_${kpad}.nii.gz" \
                                   "$FINALDIR/histo_to_mri/reslice/orig/inplane_histo_to_MR_${kpad}.nii.gz" \
                                -R "$FINALDIR/linear/volume/slices/orig/reslice_histo_${kpad}.nii.gz" \
                                   `cat ${h2m_tx}`
