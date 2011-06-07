#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh
source ../common.sh

# Read command line parameters
mov=$1
ref=$2
tx=$3
#mask=$4
#masked=$4

# tx="linear_${mov}_to_${ref}"
# tx_lowres=`sed -e "s/05p/01p/"`

# Reslice the image
$ANTSDIR/WarpImageMultiTransform 2 "$HIGRAYDIR/${mov}.nii.gz" \
                                   "$FINALDIR/linear/reslice/orig/linear_${mov}_to_${ref}.nii.gz" \
                                   `cat $LINEARDIR/accum/${tx}.txt` \
                                -R "$HIGRAYDIR/${ref}.nii.gz"

# $ANTSDIR/WarpImageMultiTransform 2 "$MASKDIR/${mask}.nii.gz" \
#                                    "$LINEARDIR/reslice/mask/${tx}_mask.nii.gz" \
#                                    `cat $LINEARDIR/accum/${tx}.txt` \
#                                 -R "$GRAYDIR/${ref}.nii.gz" --use-NN

# $ANTSDIR/WarpImageMultiTransform 2 "$MASKDIR/masked/${masked}.nii.gz" \
#                                    "$LINEARDIR/reslice/masked/${tx}_masked.nii.gz" \
#                                    `cat $LINEARDIR/accum/${tx}.txt` \
#                                 -R "$GRAYDIR/${ref}.nii.gz"


RESLICE_SPACING="${HIHSPACEX}x${HIHSPACEY}x${HIHSPACEZ}mm"

# set the voxel spacings of the slices
$C3DDIR/c3d "$FINALDIR/linear/reslice/orig/${tx}.nii.gz" \
            -spacing ${RESLICE_SPACING} -type float \
            -o "$FINALDIR/linear/reslice/orig/${tx}.nii.gz"

# $C3DDIR/c3d "$FINALDIR/linear/reslice/masked/${tx}_masked.nii.gz" \
#             -spacing ${RESLICE_SPACING} -type float \
#             -o "$FINALDIR/linear/reslice/masked/${tx}_masked.nii.gz"

# $C3DDIR/c3d "$FINALDIR/linear/reslice/mask/${tx}_mask.nii.gz" \
#             -spacing $RESLICE_SPACING \
#             -o "$FINALDIR/linear/reslice/mask/${tx}_mask.nii.gz"
