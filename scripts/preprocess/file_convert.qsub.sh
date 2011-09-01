#!/bin/bash
# request Bourne shell as shell for job
#$ -cwd -S /bin/bash

source ../common.sh

maskflag=$1 
ipad=$2
HISTO_RAWDIR=$3
image=$4
HISTO_RESIZE_RATIO=$5
PNGDIR=$6
NIFTIDIR=$7
HISTOMASK_RAWDIR=$8
mask=$9

image_outname=$ipad # this is the number of the image
spacingx=$HSPACEX
spacingy=$HSPACEY

# 1. convert the image file 

# convert the input images to png format
$MAGICKDIR/convert $HISTO_RAWDIR/${image} \
                   -resize ${HISTO_RESIZE_RATIO} -type Grayscale \
                   $PNGDIR/${image_outname}.png

# convert the png image to nii.gz image
$C3DDIR/c2d $PNGDIR/${image_outname}.png \
            -spacing ${spacingx}x${spacingy}mm \
            -o $NIFTIDIR/${image_outname}.nii.gz


# 2. convert the mask file 
# if mask files are provided, convert the mask files
if (($maskflag == 1)); then
  # get the resolution information from the image file
  res=`$MAGICKDIR/identify -verbose $PNGDIR/${image_outname}.png | grep "Geometry" | sed -e "s/Geometry: //g" | sed -e "s/+0//g"`

  # convert the input mask to png format
  $MAGICKDIR/convert $HISTOMASK_RAWDIR/${mask} \
                     -filter point -resize ${res}\! -type Grayscale \
                     $PNGDIR/mask/${image_outname}_mask.png

  # convert the png mask to nii.gz mask
  $C3DDIR/c2d $PNGDIR/mask/${image_outname}_mask.png \
              -binarize \
              -spacing ${spacingx}x${spacingy}mm \
              -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz

# if no mask file is provided, extract mask by tools Atropos
elif (($maskflag == 0)); then
  # use the whole image as the mask for the segmentation 
  $C3DDIR/c2d $NIFTIDIR/${image_outname}.nii.gz \
              -thresh 0 inf 1 0 \
              -o $NIFTIDIR/tmp/${image_outname}_id.nii.gz

  # do the segmentation
  $ANTSDIR/Atropos -a $NIFTIDIR/${image_outname}.nii.gz \
                   -d 2 \
                   -i KMeans[2] \
                   -x $NIFTIDIR/tmp/${image_outname}_id.nii.gz \
                   -m 1.0 \
                   -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz 

  # create the mask for the registration
  $C3DDIR/c2d $NIFTIDIR/mask/${image_outname}_mask.nii.gz \
              -thresh 1 1 1 0 \
              -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz
fi
