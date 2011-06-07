#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

HISTO_SLICEPATH=$1
HISTOMASK_SLICEPATH=$2
HISTO_SLICENAME=$3
HISTOMASK_SLICENAME=$4
MRI_SLICEPATH=$5
MRILABEL_SLICEPATH=$6
MRI_SLICENAME=$7
MRILABEL_SLICENAME=$8
TRG_SLICEPATH=$9
TRGLABEL_SLICEPATH=${10}
TXPATH=${11}
kpad=${12}

# HISTONEWPATH=$H2MDIR/reslice/new
# mkdir -p $HISTONEWPATH
# MRINEWPATH=$H2MDIR/mri/new
# mkdir -p $MRINEWPATH

histoslice=${HISTO_SLICENAME}${kpad}
histomaskslice=${HISTOMASK_SLICENAME}${kpad}
mrislice=${MRI_SLICENAME}${kpad}
mrilabelslice=${MRILABEL_SLICENAME}${kpad}

echo " mri slice: ${mrislice}--> histology slice: ${histoslice}"  \
> "$OUTPUTDIR/deform${mrislice}to${histoslice}.txt"

# $C3DDIR/c2d "$HISTOPATH/${histoslice}.nii.gz" -thresh 28000 Inf 0 1 \
# "$HISTOPATH/${histoslice}.nii.gz" -times -o $HISTONEWPATH/${histoslice}.nii.gz 

# $C3DDIR/c2d "$MRILABELPATH/${mrilabelslice}.nii.gz"  -thresh 1 Inf 1 0 \
# "$MRIPATH/${mrislice}.nii.gz" -times -o $MRINEWPATH/${mrislice}.nii.gz 

# $ANTSDIR/ANTS 2 -m MI["$HISTOPATH/${histoslice}.nii.gz","$MRIPATH/${mrislice}.nii.gz",1,16] \

$ANTSDIR/ANTS 2 -m MI["$HISTO_SLICEPATH/${histoslice}.nii.gz","$MRI_SLICEPATH/${mrislice}.nii.gz",1,32] \
                -t SyN[0.25] \
                -r Gauss[3] \
                -o "$TXPATH/2Ddeform_M2H_${kpad}_" \
                --affine-metric-type MI --MI-option 32x10000 \
                --rigid-affine false \
                -i 10x10\
                -x $HISTOMASK_SLICEPATH/${histomaskslice}.nii.gz \
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



$ANTSDIR/WarpImageMultiTransform 2 "$MRI_SLICEPATH/${mrislice}.nii.gz" \
                                   "$TRG_SLICEPATH/2Ddeform_M2H_${kpad}.nii.gz" \
                                   "$TXPATH/2Ddeform_M2H_${kpad}_Warp.nii.gz" \
                                   "$TXPATH/2Ddeform_M2H_${kpad}_Affine.txt" \
                                -R "$HISTO_SLICEPATH/${histoslice}.nii.gz"
                

$ANTSDIR/WarpImageMultiTransform 2 "$MRILABEL_SLICEPATH/${mrilabelslice}.nii.gz" \
                                   "$TRGLABEL_SLICEPATH/2Ddeform_M2H_label_${kpad}.nii.gz" \
                                   "$TXPATH/2Ddeform_M2H_${kpad}_Warp.nii.gz" \
                                   "$TXPATH/2Ddeform_M2H_${kpad}_Affine.txt" \
                                -R "$HISTO_SLICEPATH/${histoslice}.nii.gz" \
                                --use-NN
                                

