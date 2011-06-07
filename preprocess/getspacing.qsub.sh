#!/bin/bash
# request Bourne shell as shell for job
#$ -cwd -S /bin/bash

source ../common.sh

img=$1
INPUTPATH=$2
OUTPUTPATH=$3
REFIMG=$4

spacingx=$HSPACEX
spacingy=$HSPACEY

$C3DDIR/c2d $INPUTPATH/${img}.nii.gz \
              -spacing ${spacingx}x${spacingy}mm \
              -o $INPUTPATH/${img}.nii.gz

$C3DDIR/c2d $MASKDIR/${img}_mask.nii.gz\
              -spacing ${spacingx}x${spacingy}mm \
              -o $MASKDIR/${img}_mask.nii.gz

$ANTSDIR/WarpImageMultiTransform 2 "$INPUTPATH/${img}.nii.gz" \
                                   "$OUTPUTPATH/${img}.nii.gz" \
                                   --Id \
                                -R "$INPUTPATH/${REFIMG}.nii.gz" 

