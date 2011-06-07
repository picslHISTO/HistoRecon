#!/bin/sh
#$ -cwd -S /bin/sh
source ../common.sh

# Read the command line parameters
kpad=$1
MRISLICE_INDIR=$2
MRISLICE_INNAME=$3
HISTOSLICE_INDIR=$4
HISTOSLICE_INNAME=$5
HISTOMASKSLICE_INDIR=$6
HISTOMASKSLICE_INNAME=$7
HISTO_OUTDIR=$8

histoslice=${HISTOSLICE_INNAME}$kpad
histomaskslice=${HISTOMASKSLICE_INNAME}$kpad
mrislice=${MRISLICE_INNAME}$kpad

echo "Registering histo slice to MRI slice $kpad"

$ANTSDIR/WarpImageMultiTransform 2 \
        "$HISTOSLICE_INDIR/${histoslice}.nii.gz" \
        "$HISTO_OUTDIR/reslice/inplane_H2M_slice${kpad}.nii.gz" \
        "$HISTO_OUTDIR/tx_smooth/inplane_H2M_slice${kpad}_Affine.txt" \
     -R "$MRISLICE_INDIR/${mrislice}.nii.gz"

#                                   "$HISTO_OUTDIR/tx/inplane_histo_to_MR_${kpad}_Warp.nii.gz" \
$ANTSDIR/WarpImageMultiTransform 2 \
        "$HISTOSLICE_INDIR/mask/${histomaskslice}.nii.gz" \
        "$HISTO_OUTDIR/reslice/mask/inplane_H2M_mask_slice${kpad}.nii.gz" \
        "$HISTO_OUTDIR/tx_smooth/inplane_H2M_slice${kpad}_Affine.txt" \
     -R "$MRISLICE_INDIR/${mrislice}.nii.gz" --use-NN
                                
#                                   "$HISTO_OUTDIR/tx/inplane_histo_to_MR_${kpad}_Warp.nii.gz" \
