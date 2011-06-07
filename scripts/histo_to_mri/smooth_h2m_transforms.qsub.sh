#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh -o ./output -j y
source /home/liuyang/mouse9/scripts/common.sh

MRIPATH=$H2MDIR/mri
HISTOPATH=$H2MDIR/histo
HISTOMASKPATH=$H2MDIR/histo/mask
TRGPATH=$H2MDIR/reslice
TRGMASKPATH=$H2MDIR/reslice/mask
TXSMOOTHPATH=$H2MDIR/tx_smooth
# Read the command line parameters
mrislice=$1
histoslice=$2
histomaskslice=$3
tx_smooth=$4
# Reslice the files

$FSLDIR/flirt -ref  "$MRIPATH/${mrislice}.nii.gz" \
              -in   "$HISTOPATH/${histoslice}.nii.gz" \
              -out  "$TRGPATH/${histoslice}.nii.gz" \
              -init "$TXSMOOTHPATH/${tx_smooth}.mat" \
              -2D -applyxfm
$FSLDIR/flirt -ref  "$MRIPATH/${mrislice}.nii.gz" \
              -in   "$HISTOMASKPATH/${histomaskslice}.nii.gz" \
              -out  "$TRGMASKPATH/${histomaskslice}.nii.gz" \
              -init "$TXSMOOTHPATH/${tx_smooth}.mat" \
              -2D -applyxfm
							-interp nearestneighbour

