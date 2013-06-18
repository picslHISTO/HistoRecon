#!/bin/bash
#$ -cwd -S /bin/bash
# Set up the script environment
source ../common.sh

# input directories
HISTOMASK_INDIR="$STACKINGDIR/volume/mask"
HISTOMASK_INNAME="reslice_histo_mask"
MRIMASK_INDIR="$DATADIR/input/mri_oriented/mask"
MRIMASK_INNAME="mri_mask"

# output directories
MRIHALF_DIR=$M2HDIR/init/mrimask
HISTOHALF_DIR=$M2HDIR/init/histomask
TX_DIR=$M2HDIR/init/tx

# output file names
mkdir -p $TX_DIR
mkdir -p $MRIHALF_DIR
mkdir -p $HISTOHALF_DIR

##############################################
# 1. Create half volume
##############################################

# Get the slice with max area
echo "Get the slice with max area"
histo_idx=`$PROGDIR/findMaxArea ${HISTOMASK_INDIR}/${HISTOMASK_INNAME}.nii.gz z 1 \
| grep "Index" | sed "s/[^0-9]//g"`
let histo_ubound=$histo_idx+1

mri_idx=`$PROGDIR/findMaxArea ${MRIMASK_INDIR}/${MRIMASK_INNAME}.nii.gz z 1 \
| grep "Index" | sed "s/[^0-9]//g"`
let mri_ubound=$mri_idx+1

# Get the bounding box info
histo_dim=(`$C3DDIR/c3d ${HISTOMASK_INDIR}/${HISTOMASK_INNAME}.nii.gz -info-full \
  | grep "Image Dimension" | sed "s/[^0-9 ]//g"`)

mri_dim=(`$C3DDIR/c3d ${MRIMASK_INDIR}/${MRIMASK_INNAME}.nii.gz -info-full \
  | grep "Image Dimension" | sed "s/[^0-9 ]//g"`)

# Padding value
let histo_pad=${histo_dim[2]}-${histo_ubound}
let mri_pad=${mri_dim[2]}-${mri_ubound}

# Create the half volume mask 
echo "Create the half mask volume"
$C3DDIR/c3d ${HISTOMASK_INDIR}/${HISTOMASK_INNAME}.nii.gz \
            -region 0x0x0vox ${histo_dim[0]}x${histo_dim[1]}x${histo_ubound}vox \
            -pad 0x0x0vox 0x0x${histo_pad}vox 0 \
            -o ${HISTOHALF_DIR}/histomask.nii.gz

$C3DDIR/c3d ${MRIMASK_INDIR}/${MRIMASK_INNAME}.nii.gz \
            -region 0x0x0vox ${mri_dim[0]}x${mri_dim[1]}x${mri_ubound}vox \
            -pad 0x0x0vox 0x0x${mri_pad}vox 0 \
            -o ${MRIHALF_DIR}/mrimask.nii.gz



##############################################
# 2. Register mri to histo
##############################################

# resample the histo image to match up with the mri
echo "Resample the histo half mask" 
$C3DDIR/c3d $HISTOHALF_DIR/histomask.nii.gz \
            -resample ${mri_dim[0]}x${mri_dim[1]}x${mri_dim[2]}vox \
            -o $HISTOHALF_DIR/histomask_resample.nii.gz

# registration
echo "Register the MRI half mask to the histo half mask"

fix="$HISTOHALF_DIR/histomask_resample.nii.gz"
mov="$MRIHALF_DIR/mrimask.nii.gz"
tx="$TX_DIR/init" 
target="$MRIHALF_DIR/mrimask_warped.nii.gz" 
its=10000x10000

$ANTSDIR/antsRegistration -d 3 \
                    -r [ $fix, $mov, 1 ] \
                    -m MI[ $fix, $mov, 1, 32 ] \
                    -t affine[ 0.2 ] \
                    -c [$its,1.e-8,20]  \
                    -s 4x2vox  \
                    -f 8x4 -l 1 -o [ ${tx}_ ] 

$ANTSDIR/antsApplyTransforms -d 3 -i $mov \
                             -r $fix -n linear \
                             -t ${tx}_0GenericAffine.mat \
                             -o $target 
# $ANTSDIR/ANTS 3 -m MI["$HISTOHALF_DIR/histomask_resample.nii.gz","$MRIHALF_DIR/mrimask.nii.gz",1,32] \
#                 -o "$TX_DIR/init_" \
#                 -i 0 \
#                 --affine-metric-type MI \
#                 --MI-option 8x32000 \
#                 --number-of-affine-iterations 10000x10000
# 
# $ANTSDIR/WarpImageMultiTransform 3 "$MRIHALF_DIR/mrimask.nii.gz" \
#                                    "$MRIHALF_DIR/mrimask_warped.nii.gz" \
#                                    "$TX_DIR/init_Affine.txt"  \
#                                 -R "$HISTOHALF_DIR/histomask_resample.nii.gz"

