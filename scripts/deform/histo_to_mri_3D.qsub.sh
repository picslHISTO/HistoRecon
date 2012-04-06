#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y

source ../common.sh

MRI_VOLUME_INDIR=$1
MRI_VOLUME_INNAME=$2
# use original mri as mri input
HISTO_VOLUME_INDIR=$3
HISTO_VOLUME_INNAME=$4
HISTOMASK_VOLUME_INDIR=$5
HISTOMASK_VOLUME_INNAME=$6
# init Affine transformation file
TX_DIR=$7

HISTO_VOLUME_OUTDIR=${8}
HISTOMASK_VOLUME_OUTDIR=${9}

# registration between the original mri 
$ANTSDIR/ANTS 3 -m MI["${MRI_VOLUME_INDIR}/${MRI_VOLUME_INNAME}.nii.gz","${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz",1,32] \
                -t SyN[0.25] \
                -r Gauss[3] \
                -o "$TX_DIR/3Ddeform_H2M_" \
                --affine-metric-type MI --MI-option 32x10000 \
                --rigid-affine false \
                -i 4x4x1 \
                --number-of-affine-iterations 10000x10000x10000 

$ANTSDIR/WarpImageMultiTransform 3 "${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz" \
                                   "${HISTO_VOLUME_OUTDIR}/3Ddeform_M2H.nii.gz" \
                                   "${TX_DIR}/3Ddeform_H2M_Warp.nii.gz" \
                                   "${TX_DIR}/3Ddeform_H2M_Affine.txt" \
                                -R "${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz"
                

$ANTSDIR/WarpImageMultiTransform 3 "${HISTOMASK_VOLUME_INDIR}/${HISTOMASK_VOLUME_INNAME}.nii.gz" \
                                   "${HISTOMASK_VOLUME_OUTDIR}/3Ddeform_M2H_mask.nii.gz" \
                                   "${TX_DIR}/3Ddeform_H2M_Warp.nii.gz" \
                                   "${TX_DIR}/3Ddeform_H2M_Affine.txt" \
                                -R "${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz" \
                                --use-NN

# Get the information for spacing
spacingx=$HSPACEX
spacingy=$RESPACEY
spacingz=$RESPACEZ

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        ${HISTO_VOLUME_OUTDIR}/3Ddeform_H2M.nii.gz \
        ${HISTO_VOLUME_OUTDIR}/3Ddeform_H2M_oriented.nii.gz \
        $HISTO_REV_ORIENT

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_H2M_mask.nii.gz \
        ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_H2M_mask_oriented.nii.gz \
        $HISTO_REV_ORIENT

$C3DDIR/c3d ${MRI_VOLUME_OUTDIR}/3Ddeform_H2M_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o "${MRI_VOLUME_OUTDIR}/3Ddeform_H2M_oriented.nii.gz" 

$C3DDIR/c3d ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_H2M_mask_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o "${MRILABEL_VOLUME_OUTDIR}/3Ddeform_H2M_mask_oriented.nii.gz" 

