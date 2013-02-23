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
spacingx=$RESPACEX
spacingy=$RESPACEY

# 1. convert the image file 
# convert the input images to png format
# Use c3d to convert directly
# Decide whether it's multiple component
mc=`$C3DDIR/c2d -mcs $HISTO_RAWDIR/${image} -info | awk -F'[#:]' '{print $2}'`
if (($mc == 3));then
  $C3DDIR/c2d -mcs $HISTO_RAWDIR/${image} \
              -wsum 0.29900 0.58700 0.11400 \
              -resample ${HISTO_RESIZE_RATIO} \
              -spacing ${spacingx}x${spacingy}mm \
              -o $NIFTIDIR/${image_outname}.nii.gz
else
  $C3DDIR/c2d $HISTO_RAWDIR/${image} \
              -resample ${HISTO_RESIZE_RATIO} \
              -spacing ${spacingx}x${spacingy}mm \
              -o $NIFTIDIR/${image_outname}.nii.gz
fi

# when convert is not working, use matlab 
# $MATLABDIR/matlab -nodesktop -nosplash -nojvm -r \
#                   "img = imread('$HISTO_RAWDIR/${image}'); 
#                   size_resize = size_img(1:2)*${HISTO_RESIZE_RATIO}; 
#                   imwrite(imresize(rgb2gray(img),size_resize),'${PNGDIR}/${image_outname}.png');
#                   quit;"

# 2. convert the mask file 
# if mask files are provided, convert the mask files
if (($maskflag == 1)); then
  # get the resolution information from the image file
  res=`$C3DDIR/c2d $NIFTIDIR/${image_outname}.nii.gz \
    -info | awk '{print $5 $6}' | sed "s/,/x/g" | sed -e "s/[^0-9x]//g"`

  # $MATLABDIR/matlab -nodesktop -nosplash -nojvm -r \
  #                 "img = imread('$HISTOMASK_RAWDIR/${mask}'); \
  #                 size_resize = ${res}; \
  #                 imwrite(imresize(rgb2gray(img),size_resize),'${PNGDIR}/mask/${image_outname}_mask.png'); \
  #                 quit;"

  # convert the png mask to nii.gz mask
  $C3DDIR/c2d $HISTOMASK_RAWDIR/${mask} \
              -binarize \
              -resample $res \
              -spacing ${spacingx}x${spacingy}mm \
              -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz

# if no mask file is provided, extract mask by tools Atropos
elif (($maskflag == 0)); then
#   # use the whole image as the mask for the segmentation 
#   $C3DDIR/c2d $NIFTIDIR/${image_outname}.nii.gz \
#               -thresh 0 inf 1 0 \
#               -o $NIFTIDIR/tmp/${image_outname}_id.nii.gz
# 
#   # do the segmentation
#   $ANTSDIR/Atropos -a $NIFTIDIR/${image_outname}.nii.gz \
#                    -d 2 \
#                    -i KMeans[2] \
#                    -x $NIFTIDIR/tmp/${image_outname}_id.nii.gz \
#                    -m 1.0 \
#                    -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz 
# 
#   # create the mask for the registration
#   $C3DDIR/c2d $NIFTIDIR/mask/${image_outname}_mask.nii.gz \
#               -thresh 1 1 1 0 \
#               -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz

  # use thresholding for the segmentation 
 
  $C3DDIR/c2d $NIFTIDIR/${image_outname}.nii.gz \
              -thresh 88% inf 0 1 \
              -dilate 1 5x5vox \
              -connected-components -thresh 1 1 1 0 \
              -o $NIFTIDIR/mask/${image_outname}_mask.nii.gz 

  # Generate mask using levelset segmentation
  # $C3DDIR/c2d "$NIFTIDIR/${image_outname}.nii.gz" \
  #             -smooth 2vox \
  #             -pim Range \
  #             -thresh 96% inf -1 1 \
  #             "$NIFTIDIR/${image_outname}.nii.gz" \
  #             -thresh 96% inf -1 1 \
  #             -levelset-curvature 10.0 -levelset 150 \
  #             -thresh -inf 0 0 1 \
  #             -connected-components -thresh 1 1 1 0 \
  #             -dilate 1 10x10vox \
  #             -o "$NIFTIDIR/mask/${image_outname}_mask.nii.gz"
fi


