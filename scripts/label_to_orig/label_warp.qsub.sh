#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y


# compose all the transforms back to the original input histo slice
# 1) compose from the iterative match procedure
# 2) compose the shortest path procedure
# 3) warp the MRI label (after iterative match) using the INVERSE of the previous
#    composite result transform

source ../common.sh

ipad=$1
num=$2



for ((k=$H2M_NITER; k> 0; k--))
do
  echo '-i' `ls $H2MDIR/iter$k/tx/*.txt | head -n $num | tail -n 1` >> $LABELDIR/tx/label$ipad.txt
done
  echo '-i' `ls $STACKINGDIR/accum/*.txt | head -n $num | tail -n 1 ` >> $LABELDIR/tx/label$ipad.txt
  echo '-R' `ls $GRAYDIR/*.nii.gz | head -n $num | tail -n 1` >> $LABELDIR/tx/label$ipad.txt

$ANTSDIR/WarpImageMultiTransform 2 "$DEFORMDIR/reslice/label/2Ddeform_M2H_label_${ipad}.nii.gz" \
                                   "$LABELDIR/padded/label_${ipad}.nii.gz" \
                                   `echo $(cat $LABELDIR/tx/label${ipad}.txt)` \
                                   --use-NN

# unpad all images using the original size and padding ratio
# the image of the unpadded size
image=`ls $NIFTIDIR | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//g" | head -n $num | tail -n 1`

# input image (padded)
image_padded=label_${ipad}

# get image information
sizex=`$C3DDIR/c2d "$NIFTIDIR/${image}.nii.gz" \
          -info-full | grep " dim\[1\]" | sed -e "s/dim\[1\] = //g" | sed -e "s/\ //g"`
sizey=`$C3DDIR/c2d "$NIFTIDIR/${image}.nii.gz" \
          -info-full | grep " dim\[2\]" | sed -e "s/dim\[2\] = //g" | sed -e "s/\ //g"`
let padx=$sizex*HISTO_PAD_PERCENT/100
let pady=$sizey*HISTO_PAD_PERCENT/100

# extract region 
$C3DDIR/c2d $LABELDIR/padded/${image_padded}.nii.gz \
    -region ${padx}x${pady}vox ${sizex}x${sizey}vox \
      -type uchar \
   -spacing 1x1mm \
         -o $LABELDIR/unpadded/${image}.nii.gz

size_high=`$MAGICKDIR/identify -verbose $HISTO_RAWDIR/$(ls $HISTO_RAWDIR | head -n $num | tail -n 1) \
  | grep "Geometry" | sed -e "s/Geometry: //g" | sed -e "s/+0//g"`

echo $size_high

$C3DDIR/c2d $LABELDIR/unpadded/${image}.nii.gz \
  -resample ${size_high}vox \
      -type uchar \
         -o $LABELDIR/orig/${image}.png
