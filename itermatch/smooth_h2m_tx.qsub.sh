#!/bin/sh
#$ -cwd -S /bin/sh
source ../common.sh

# Read the command line parameters
histoslice=$1
k=`printf "%05d" $2`

# Reslice the files
$FSLDIR/flirt -ref  "$H2MDIR/mri/affine_MRI2H_slice_${k}.nii.gz" \
              -in   "$LINEARDIR/reslice/orig/${histoslice}.nii.gz" \
              -out  "$SMOOTHDIR/reslice/orig/rigid_histo_to_MR_${k}.nii.gz" \
              -init "$SMOOTHDIR/tx_smooth/rigid_histo_to_MR_${k}_smooth.mat" \
              -2D -applyxfm

$FSLDIR/flirt -ref  "$H2MDIR/mri/affine_MRI2H_slice_${k}.nii.gz" \
              -in   "$LINEARDIR/reslice/mask/${histoslice}_mask.nii.gz" \
              -out  "$SMOOTHDIR/reslice/mask/rigid_histo_to_MR_${k}_mask.nii.gz" \
              -init "$SMOOTHDIR/tx_smooth/rigid_histo_to_MR_${k}_smooth.mat" \
              -2D -applyxfm

$FSLDIR/flirt -ref  "$H2MDIR/mri/affine_MRI2H_slice_${k}.nii.gz" \
              -in   "$LINEARDIR/reslice/masked/${histoslice}_masked.nii.gz" \
              -out  "$SMOOTHDIR/reslice/masked/rigid_histo_to_MR_${k}_masked.nii.gz" \
              -init "$SMOOTHDIR/tx_smooth/rigid_histo_to_MR_${k}_smooth.mat" \
              -2D -applyxfm
