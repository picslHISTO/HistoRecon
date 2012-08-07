#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

MRILABEL_INDIR=$1
MRILABEL_SLICE_NAME=$2
ipad=$3
num=$4

for ((k=$H2M_NUM_ITER; k> 0; k--)); do
  echo '-i' `ls $H2MDIR/iter$k/tx/*.txt | head -n $num | tail -n 1` \
      >> $LABELDIR/tx/label$ipad.txt
done

echo '-i' `ls $STACKINGDIR/accum/*.txt | head -n $num | tail -n 1 ` \
    >> $LABELDIR/tx/label$ipad.txt
echo '-R' `ls $GRAYDIR/*.nii.gz | head -n $num | tail -n 1` \
    >> $LABELDIR/tx/label$ipad.txt

$ANTSDIR/WarpImageMultiTransform 2 "${MRILABEL_INDIR}/${MRILABEL_SLICE_NAME}${ipad}.nii.gz" \
                                   "$LABELDIR/padded/label_${ipad}.nii.gz" \
                                   `echo $(cat $LABELDIR/tx/label${ipad}.txt)` \
                                   --use-NN

# the image of the unpadded size
image=`ls $NIFTIDIR | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//g" | head -n $num | tail -n 1`

# input image (padded)
image_padded=`ls $LABELDIR/padded | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//g" | head -n $num | tail -n 1`
histo_dim=(`$C3DDIR/c2d $NIFTIDIR/${image}.nii.gz -info-full \
  | grep "Image Dimension" | sed "s/[^0-9 ]//g"`)

sizex=${histo_dim[0]}
sizey=${histo_dim[1]}
let padx=$sizex*HISTO_PAD_PERCENT/100
let pady=$sizey*HISTO_PAD_PERCENT/100

# extract region 
$C3DDIR/c2d $LABELDIR/padded/${image_padded}.nii.gz \
            -region ${padx}x${pady}vox ${sizex}x${sizey}vox \
            -type uchar \
            -o $LABELDIR/unpadded/${image}.nii.gz

size_high=`$MAGICKDIR/identify -verbose $HISTO_RAWDIR/$(ls $HISTO_RAWDIR | head -n $num | tail -n 1) \
  | grep "Geometry" | sed -e "s/Geometry: //g" | sed -e "s/+0//g"`

echo $size_high

$C3DDIR/c2d $LABELDIR/unpadded/${image}.nii.gz \
            -resample ${size_high}vox \
            -type uchar \
            -o $LABELDIR/orig/${image}.png
