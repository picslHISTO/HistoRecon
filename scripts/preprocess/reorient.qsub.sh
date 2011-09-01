#!/bin/bash
# request Bourne shell as shell for job
#$ -cwd -S /bin/bash

source ../common.sh

img=$1
INPUTPATH=$2
OUTPUTPATH=$3
REFIMG=$4

$ANTSDIR/WarpImageMultiTransform 2 "$INPUTPATH/${img}.nii.gz" \
                                   "$OUTPUTPATH/${img}.nii.gz" \
                                   --Id \
                                -R "$INPUTPATH/${REFIMG}.nii.gz" 

