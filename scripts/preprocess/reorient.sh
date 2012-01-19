#!/bin/bash
# ==============================
# get spacing of the image
# from $GRAYDIR to $GRAYDIR (using the same 
#  filename in the same directory)
# also flip/permute axis of 3D Histo image
# save in  VOLUMEPATH=$DATADIR/input/histo/volume
# this is for visualization only
# and also flip/permute axis of 3D MRI 
# image in the reverse order
# save in MRI_OUTDIR="$DATADIR/input/mri_oriented
# ==============================

source ../common.sh
spacingx=$RESPACEX
spacingy=$RESPACEY
spacingz=$HSPACEZ
orient=${HISTO_ORIENT}
flip=${HISTO_FLIP}

if [ -n "$flip" ] 
then
	flip_option="-flip $flip"
else
	flip_option=''
fi 

INPUTPATH=$GRAYDIR
OUTPUTPATH=$DATADIR/input/histo/tmp
VOLUMEPATH=$DATADIR/input/histo/volume

# make sure the directories exist 
mkdir -p $OUTPUTPATH
mkdir -p $VOLUMEPATH

# make sure the directories are clean
num=`ls -1 $INPUTPATH | wc -l`
REFIMG=`ls -1 $INPUTPATH | grep "\.nii\.gz" | head -n $((num/2)) | tail -n 1 | sed "s/\.nii\.gz//g"`
rm -rf $OUTPUTPATH/*.*
rm -rf $VOLUMEPATH/*.*

echo "Set spacing and transform all the histology image to a common space"

for img in `ls -1 $INPUTPATH | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//g"`
do
  exe "reorient-$img" 1 reorient.qsub.sh \
  $img $INPUTPATH $OUTPUTPATH $REFIMG
done

qblock "reorient"

$PROGDIR/imageSeriesToVolume -o "$VOLUMEPATH/volume.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $OUTPUTPATH/*.nii.gz | sort`

# flip option should go before the permute axis
$C3DDIR/c3d $VOLUMEPATH/volume.nii.gz \
$flip_option \
-pa $orient \
-orient RAI -origin 0x0x0mm \
-o $VOLUMEPATH/volume.nii.gz

# Record the information for the reoriented data
rm $PARMDIR/spacing_reoriented.txt
$C3DDIR/c3d $VOLUMEPATH/volume.nii.gz -info-full | grep "pixdim\[[1-3]\]"  | \
sed -r "s/pixdim\[[1-3]\] = //g" | sed "s/ //g" \
>> $PARMDIR/spacing_reoriented.txt

# For the inverse transform
orient_inverse=''
if [[ ${orient:0:1} == 'x' ]]; then
  orient_inverse=${orient_inverse}x
elif [[ ${orient:1:1} == 'x' ]]; then
  orient_inverse=${orient_inverse}y
elif [[ ${orient:2:1} == 'x' ]]; then
  orient_inverse=${orient_inverse}z
fi

if [[ ${orient:0:1} == 'y' ]]; then
  orient_inverse=${orient_inverse}x
elif [[ ${orient:1:1} == 'y' ]]; then
  orient_inverse=${orient_inverse}y
elif [[ ${orient:2:1} == 'y' ]]; then
  orient_inverse=${orient_inverse}z
fi

if [[ ${orient:0:1} == 'z' ]]; then
  orient_inverse=${orient_inverse}x
elif [[ ${orient:1:1} == 'z' ]]; then
  orient_inverse=${orient_inverse}y
elif [[ ${orient:2:1} == 'z' ]]; then
  orient_inverse=${orient_inverse}z
fi

echo "reorient the mri images"

MRI_OUTDIR="$DATADIR/input/mri_oriented"
MRI_OUTNAME="mri"
MRILABEL_OUTDIR="$DATADIR/input/mri_oriented/label"
MRILABEL_OUTNAME="mri_label"
MRIMASK_OUTDIR="$DATADIR/input/mri_oriented/mask"
MRIMASK_OUTNAME="mri_mask"
mkdir -p $MRI_OUTDIR
mkdir -p $MRILABEL_OUTDIR
mkdir -p $MRIMASK_OUTDIR

cp ${MRI_WAXHOLM_FILE} $MRI_OUTDIR/${MRI_OUTNAME}_oriented.nii.gz
cp ${MRILABEL_WAXHOLM_FILE} $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}_oriented.nii.gz
$C3DDIR/c3d ${MRILABEL_WAXHOLM_FILE} \
            -thresh 1 inf 1 0 \
            -o $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}_oriented.nii.gz


# If you use the inverse you should apply reorient first then flip
# The given mri image is the standard orientation (here named after _oriented)
# Here we permute the axis to match with the direction of the input histology image

$C3DDIR/c3d $MRI_OUTDIR/${MRI_OUTNAME}_oriented.nii.gz \
-pa $orient_inverse \
$flip_option \
-orient RAI -origin 0x0x0mm \
-o $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz 

$C3DDIR/c3d $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}_oriented.nii.gz \
-pa $orient_inverse \
$flip_option \
-orient RAI -origin 0x0x0mm \
-o $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}.nii.gz 

$C3DDIR/c3d $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}_oriented.nii.gz \
-pa $orient_inverse \
$flip_option \
-orient RAI -origin 0x0x0mm \
-o $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}.nii.gz 



