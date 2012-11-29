#!/bin/bash
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

histo_slice=$1
mri_slice=$2
histo_dir=$MANUALDIR/histo/slices
histo_outdir=$MANUALDIR/histo/slices_out
mri_dir=$MANUALDIR/mri/slices_out
tx_dir=$MANUALDIR/tx
tx_file="${mri_slice}"

mkdir -p $tx_dir

$ANTSDIR/ANTS 2 \
             -m MI["$mri_dir/${mri_slice}.nii.gz","$histo_dir/${histo_slice}.nii.gz",1,32] \
             -o "$tx_dir/${tx_file}_" \
             -i 40x0x0 \
             --affine-metric-type MI \
             --MI-option 32x10000 \
             --number-of-affine-iterations 10000x10000x10000 

$ANTSDIR/WarpImageMultiTransform 2 "$histo_dir/${histo_slice}.nii.gz" \
                                   "$histo_outdir/${histo_slice}.nii.gz" \
                                   "$tx_dir/${tx_file}_Warp.nii.gz" \
                                   "$tx_dir/${tx_file}_Affine.txt" \
                                -R "$mri_dir/${mri_slice}.nii.gz"


