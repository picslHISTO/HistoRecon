#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

HISTO_SLICE_INDIR=$1
HISTO_SLICE_INNAME=$2
HISTOMASK_SLICE_INDIR=$3
HISTOMASK_SLICE_INNAME=$4
TX_DIR=$5
MRI_SLICE_INDIR=$6
MRI_SLICE_INNAME=$7
MRILABEL_SLICE_INDIR=$8
MRILABEL_SLICE_INNAME=$9
MRI_SLICE_OUTDIR=${10}
MRILABEL_SLICE_OUTDIR=${11}
kpad=${12}


# HISTONEWPATH=$H2MDIR/reslice/new
# mkdir -p $HISTONEWPATH
# MRINEWPATH=$H2MDIR/mri/new
# mkdir -p $MRINEWPATH

histoslice=${HISTO_SLICE_INNAME}${kpad}
histomaskslice=${HISTOMASK_SLICE_INNAME}${kpad}
mrislice=${MRI_SLICE_INNAME}${kpad}
mrilabelslice=${MRILABEL_SLICE_INNAME}${kpad}

echo " mri slice: ${mrislice}--> histology slice: ${histoslice}" 

# $C3DDIR/c2d "$HISTOPATH/${histoslice}.nii.gz" -thresh 28000 Inf 0 1 \
# "$HISTOPATH/${histoslice}.nii.gz" -times -o $HISTONEWPATH/${histoslice}.nii.gz 

# $C3DDIR/c2d "$MRILABELPATH/${mrilabelslice}.nii.gz"  -thresh 1 Inf 1 0 \
# "$MRIPATH/${mrislice}.nii.gz" -times -o $MRINEWPATH/${mrislice}.nii.gz 

# $ANTSDIR/ANTS 2 -m MI["$HISTOPATH/${histoslice}.nii.gz","$MRIPATH/${mrislice}.nii.gz",1,16] \

$ANTSDIR/ANTS 2 -m MI["${HISTO_SLICE_INDIR}/${histoslice}.nii.gz","${MRI_SLICE_INDIR}/${mrislice}.nii.gz",1,32] \
                -t SyN[0.25] \
                -r Gauss[3] \
                -o "${TX_DIR}/2Ddeform_M2H_${kpad}_" \
                --affine-metric-type MI --MI-option 32x10000 \
                --rigid-affine false \
                -i 10x10\
                -x ${HISTOMASK_SLICE_INDIR}/${histomaskslice}.nii.gz \
                --continue-affine false

#                --number-of-affine-iterations 10000x10000x10000 \


# $ANTSDIR/ANTS 2 -m MI["$HISTONEWPATH/${histoslice}.nii.gz","$MRINEWPATH/${mrislice}.nii.gz",1,32] \
#                -t Elast[0.25,0] \
#                -r Gauss[10,0.1] \
#                -o "$TXPATH/inplane_MR_to_histo_${kpad}_" \
#                --affine-metric-type MI --MI-option 32x10000 \
#                --rigid-affine false \
#                -i 100x100x100\
#                --number-of-affine-iterations 10000x10000x10000 
#								-x $HISTOMASKPATH/${histomaskslice}.nii.gz



$ANTSDIR/WarpImageMultiTransform 2 "${MRI_SLICE_INDIR}/${mrislice}.nii.gz" \
                                   "${MRI_SLICE_OUTDIR}/2Ddeform_M2H_${kpad}.nii.gz" \
                                   "${TX_DIR}/2Ddeform_M2H_${kpad}_Warp.nii.gz" \
                                   "${TX_DIR}/2Ddeform_M2H_${kpad}_Affine.txt" \
                                -R "${HISTO_SLICE_INDIR}/${histoslice}.nii.gz"
                

$ANTSDIR/WarpImageMultiTransform 2 "${MRILABEL_SLICE_INDIR}/${mrilabelslice}.nii.gz" \
                                   "${MRILABEL_SLICE_OUTDIR}/2Ddeform_M2H_label_${kpad}.nii.gz" \
                                   "${TX_DIR}/2Ddeform_M2H_${kpad}_Warp.nii.gz" \
                                   "${TX_DIR}/2Ddeform_M2H_${kpad}_Affine.txt" \
                                -R "${HISTO_SLICE_INDIR}/${histoslice}.nii.gz" \
                                --use-NN
                                

