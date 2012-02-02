#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y

source ../common.sh

HISTO_VOLUME_INDIR=$1
HISTO_VOLUME_INNAME=$2
# use original mri as mri input
MRI_INDIR=$3
MRI_INNAME=$4
MRILABEL_INDIR=$5
MRILABEL_INNAME=$6
# init Affine transformation file
TX_INIT_DIR=$7
TX_INIT_NAME=$8
TX_DIR=$9

MRI_VOLUME_OUTDIR=${10}
MRILABEL_VOLUME_OUTDIR=${11}
MRI_SLICE_OUTDIR=${12}
MRILABEL_SLICE_OUTDIR=${13}


# registration between the original mri 
$ANTSDIR/ANTS 3 -m MI["${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz","${MRI_INDIR}/${MRI_INNAME}.nii.gz",1,32] \
                -t SyN[0.25] \
                -r Gauss[3] \
                -o "$TX_DIR/3Ddeform_M2H_" \
                -a "${TX_INIT_DIR}/${TX_INIT_NAME}" \
                --affine-metric-type MI --MI-option 32x10000 \
                --rigid-affine false \
                -i 40x40x10 \
                --number-of-affine-iterations 10000x10000x10000 

$ANTSDIR/WarpImageMultiTransform 3 "${MRI_INDIR}/${MRI_INNAME}.nii.gz" \
                                   "${MRI_VOLUME_OUTDIR}/3Ddeform_M2H.nii.gz" \
                                   "${TX_DIR}/3Ddeform_M2H_Warp.nii.gz" \
                                   "${TX_DIR}/3Ddeform_M2H_Affine.txt" \
                                -R "${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz"
                

$ANTSDIR/WarpImageMultiTransform 3 "${MRILABEL_INDIR}/${MRILABEL_INNAME}.nii.gz" \
                                   "${MRILABEL_VOLUME_OUTDIR}/3Ddeform_M2H_label.nii.gz" \
                                   "${TX_DIR}/3Ddeform_M2H_Warp.nii.gz" \
                                   "${TX_DIR}/3Ddeform_M2H_Affine.txt" \
                                -R "${HISTO_VOLUME_INDIR}/${HISTO_VOLUME_INNAME}.nii.gz" \
                                --use-NN

echo "Making MRI slices ..."

$PROGDIR/ConvertImageSeries ${MRI_SLICE_OUTDIR} 3Ddeform_M2H_%05d.nii.gz ${MRI_VOLUME_OUTDIR}/3Ddeform_M2H.nii.gz 
$PROGDIR/ConvertImageSeries ${MRILABEL_SLICE_OUTDIR} 3Ddeform_M2H_label_%05d.nii.gz ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_M2H_label.nii.gz 

# Get the information for spacing
spacingx=$HSPACEX
spacingy=$RESPACEY
spacingz=$RESPACEZ

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        ${MRI_VOLUME_OUTDIR}/3Ddeform_M2H.nii.gz \
        ${MRI_VOLUME_OUTDIR}/3Ddeform_M2H_oriented.nii.gz \
        $HISTO_REV_ORIENT

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_M2H_label.nii.gz \
        ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_M2H_label_oriented.nii.gz \
        $HISTO_REV_ORIENT

$C3DDIR/c3d ${MRI_VOLUME_OUTDIR}/3Ddeform_M2H_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o "${MRI_VOLUME_OUTDIR}/3Ddeform_M2H_oriented.nii.gz" 

$C3DDIR/c3d ${MRILABEL_VOLUME_OUTDIR}/3Ddeform_M2H_label_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o "${MRILABEL_VOLUME_OUTDIR}/3Ddeform_M2H_label_oriented.nii.gz" 

