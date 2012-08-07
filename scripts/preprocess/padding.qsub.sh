#!/bin/bash
# request Bourne shell as shell for job
#$ -cwd -S /bin/bash

source ../common.sh

image=$1

array=(`$C3DDIR/c2d "$NIFTIDIR/${image}.nii.gz" \
			"$NIFTIDIR/mask/${image}_mask.nii.gz" \
            -label-statistics \
			| head -n 2 | tail -n 1`)

# get the background mean value to use to pad the histology images			
bkgd_mean=${array[1]}
histo_dim=(`$C3DDIR/c2d $NIFTIDIR/${image}.nii.gz -info-full \
  | grep "Image Dimension" | sed "s/[^0-9 ]//g"`)

sizex=${histo_dim[0]}
sizey=${histo_dim[1]}
let padx=$sizex*HISTO_PAD_PERCENT/100
let pady=$sizey*HISTO_PAD_PERCENT/100

# pad the images, the masks 
$C3DDIR/c2d "$NIFTIDIR/${image}.nii.gz" \
       -pad ${padx}x${pady}vox ${padx}x${pady}vox ${bkgd_mean} \
         -o "$GRAYDIR/${image}.nii.gz"

$C3DDIR/c2d "$GRAYDIR/${image}.nii.gz" \
    -origin 0x0mm \
         -o "$GRAYDIR/${image}.nii.gz"

$C3DDIR/c2d "$NIFTIDIR/mask/${image}_mask.nii.gz" \
       -pad ${padx}x${pady}vox ${padx}x${pady}vox 0 \
         -o "$MASKDIR/${image}_mask.nii.gz"

$C3DDIR/c2d "$MASKDIR/${image}_mask.nii.gz" \
    -origin 0x0mm \
         -o "$MASKDIR/${image}_mask.nii.gz"

