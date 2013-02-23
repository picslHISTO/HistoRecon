#!/bin/sh
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

HISTO_SLICE_INDIR=$1
HISTO_SLICE_INNAME=$2
HISTOMASK_SLICE_INDIR=$3
HISTOMASK_SLICE_INNAME=$4
MRI_SLICE_INDIR=$5
MRI_SLICE_INNAME=$6
TX_DIR=$7
HISTO_SLICE_OUTDIR=$8
HISTOMASK_SLICE_OUTDIR=$9
kpad=${10}

histoslice=${HISTO_SLICE_INNAME}${kpad}
histomaskslice=${HISTOMASK_SLICE_INNAME}${kpad}
mrislice=${MRI_SLICE_INNAME}${kpad}

echo " histo slice: ${mrislice} --> MR slice: ${histoslice}" 

# $C3DDIR/c2d "$HISTOPATH/${histoslice}.nii.gz" -thresh 28000 Inf 0 1 \
# "$HISTOPATH/${histoslice}.nii.gz" -times -o $HISTONEWPATH/${histoslice}.nii.gz 

# $C3DDIR/c2d "$MRILABELPATH/${mrilabelslice}.nii.gz"  -thresh 1 Inf 1 0 \
# "$MRIPATH/${mrislice}.nii.gz" -times -o $MRINEWPATH/${mrislice}.nii.gz 

# $ANTSDIR/ANTS 2 -m MI["$HISTOPATH/${histoslice}.nii.gz","$MRIPATH/${mrislice}.nii.gz",1,16] \

$ANTSDIR/ANTS 2 -m CC["${MRI_SLICE_INDIR}/${mrislice}.nii.gz","${HISTO_SLICE_INDIR}/${histoslice}.nii.gz",1,32] \
                -t SyN[0.25] \
                -r Gauss[3] \
                -o "${TX_DIR}/2Ddeform_H2M_${kpad}_" \
                --affine-metric-type MI --MI-option 32x10000 \
                --rigid-affine false \
                -i 10x10\
                -x ${HISTOMASK_SLICE_INDIR}/${histomaskslice}.nii.gz \
                --continue-affine false


$ANTSDIR/WarpImageMultiTransform 2 "${HISTO_SLICE_INDIR}/${histoslice}.nii.gz" \
                                   "${HISTO_SLICE_OUTDIR}/2Ddeform_H2M_${kpad}.nii.gz" \
                                   "${TX_DIR}/2Ddeform_H2M_${kpad}_Warp.nii.gz" \
                                   "${TX_DIR}/2Ddeform_H2M_${kpad}_Affine.txt" \
                                -R "${MRI_SLICE_INDIR}/${mrislice}.nii.gz"
                

$ANTSDIR/WarpImageMultiTransform 2 "${HISTOMASK_SLICE_INDIR}/${histomaskslice}.nii.gz" \
                                   "${HISTOMASK_SLICE_OUTDIR}/2Ddeform_H2M_mask_${kpad}.nii.gz" \
                                   "${TX_DIR}/2Ddeform_H2M_${kpad}_Warp.nii.gz" \
                                   "${TX_DIR}/2Ddeform_H2M_${kpad}_Affine.txt" \
                                -R "${MRI_SLICE_INDIR}/${mrislice}.nii.gz" \
                                --use-NN


