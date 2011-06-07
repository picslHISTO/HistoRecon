#!/bin/bash
# request Bourne shell as shell for job
#$ -cwd -S /bin/bash

source ../common.sh

maskflag=$1 
HISTO_RAWDIR=$2
image=$3
HISTO_RESIZE_RATIO=$4
PNGDIR=$5
NIFTIDIR=$6
HISTOMASK_RAWDIR=$7
mask=$8

# 1. convert the image file 

# convert the input images to png format
$MAGICKDIR/convert $HISTO_RAWDIR/${image} -resize ${HISTO_RESIZE_RATIO} -type Grayscale $PNGDIR/${image%.*}.png

# convert the png image to nii.gz image
$C3DDIR/c2d $PNGDIR/${image%.*}.png -o $NIFTIDIR/${image%.*}.nii.gz


# 2. convert the mask file 
# if mask files are provided, convert the mask files
if (($maskflag == 1)); then
# get the resolution information from the image file
    res=`$MAGICKDIR/identify -verbose $PNGDIR/${image%.*}.png | grep "Geometry" | sed -e "s/Geometry: //g" | sed -e "s/+0//g"`

# convert the input mask to png format
    $MAGICKDIR/convert $HISTOMASK_RAWDIR/${mask} -filter point -resize ${res}\! -type Grayscale $PNGDIR/mask/${image%.*}_mask.png

# convert the png mask to nii.gz mask
    $C3DDIR/c2d $PNGDIR/mask/${image%.*}_mask.png -binarize -o $NIFTIDIR/mask/${image%.*}_mask.nii.gz

# if there is no mask file provided by the user, extract mask by tools Atropos
elif (($maskflag == 0)); then
  # use the whole image as the mask for the segmentation 
  $C3DDIR/c2d $NIFTIDIR/${image%.*}.nii.gz -thresh 0 inf 1 0 -o $NIFTIDIR/tmp/${image%.*}_id.nii.gz

  # do the segmentation
  $ANTSDIR/Atropos -a $NIFTIDIR/${image%.*}.nii.gz -d 2 -i KMeans[2] -x $NIFTIDIR/tmp/${image%.*}.nii.gz -m 1.0 -o $NIFTIDIR/mask/${image%.*}_mask.nii.gz 

  # create the mask for the registration
  $C3DDIR/c2d $NIFTIDIR/mask/${image%.*}_mask.nii.gz -thresh 1 1 1 0 -o $NIFTIDIR/mask/${image%.*}_mask.nii.gz
fi
