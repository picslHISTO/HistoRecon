#!/bin/bash
# Set up the script environment

# padding all the images in $NIFTIDIR
# with specified ratio 
#  $HISTO_PAD_PERCENT, defined in common.sh
# to direcotry $GRAYDIR

source ../common.sh


OUTPUTPATH=$GRAYDIR
MASKOUTPUTPATH=$GRAYDIR/mask

# make sure the directories exist
mkdir -p $OUTPUTPATH
mkdir -p $MASKOUTPUTPATH

echo "pad the nii image and the mask"

for img in `ls -1 $NIFTIDIR | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//g"`
do
  qsub -N "padding-${img}" -o $OUTPUTDIR -e $ERRORDIR padding.qsub.sh ${img} 
done

qblock