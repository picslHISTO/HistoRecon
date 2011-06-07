#!/bin/bash
# ==============================
# File converting
# 1) convert each image in the raw directory to 
# .png in $PNGDIR (input/histo/png)
# and then to nii.gz file in the gray directory
# $NIFTIDIR (input/histo/nii, currently defined in 
#  common.sh)
# 2) Downsampling is done here.
# 3) Mask is generated (using Atropos) 
#  here if no masks provided.
# ==============================

source ../common.sh

# make sure the directory exists
PNGDIR=$DATADIR/input/histo/png
mkdir -p $PNGDIR

# make sure the directory is clean
# rm -rf $PNGDIR/*.*
# rm -rf $NIFTIDIR/*.*


# convert is required on the machine
# use qsub
# NOTE: here variables $img contain file extensions, they can vary

# use two arrays store the file names of histology and mask raw data
listfile=(`ls -1 $HISTO_RAWDIR`)
maskfile=(`ls -1 $HISTOMASK_RAWDIR`)

# maskflag is used to see whether the we need to convert the mask file
maskflag=0;

if [[ -n ${HISTOMASK_RAWDIR} && -n $(ls ${HISTOMASK_RAWDIR}) ]]; then
  if ((${#listfile[*]} == ${#maskfile[*]})); then
    maskflag=1;
    mkdir -p $PNGDIR/mask
    mkdir -p $NIFTIDIR/mask
  else
    echo "the number of the image files and the number of mask files does not match"
  fi

elif (($maskflag == 0)); then
  mkdir -p $NIFTIDIR/tmp 
  mkdir -p $NIFTIDIR/mask
fi


for ((i=0; i<${#listfile[*]}; i++)) 
do
  qsub -pe serial 2 -N "image-${listfile[$i]}-conversion" -o $OUTPUTDIR -e $ERRORDIR file_convert.qsub.sh \
  $maskflag \
  $HISTO_RAWDIR ${listfile[$i]} $HISTO_RESIZE_RATIO $PNGDIR $NIFTIDIR $HISTOMASK_RAWDIR ${maskfile[$i]} \

done

qblock


