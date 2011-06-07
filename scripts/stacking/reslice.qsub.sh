#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

# Read command line parameters
mov=$1
ref=$2
mask=$3
ipad=$4


tx="linear_${mov}_to_${ref}"

# Reslice the image
if (( ${LINEAR_RECON_ANTS} == 0 || ${LINEAR_RECON_ANTS} == 1 )); then
	# using ANTS (valid for both affine and deformable registration, since accumulation file contains
	# the affine and deformable transformations
  $ANTSDIR/WarpImageMultiTransform 2 "$GRAYDIR/${mov}.nii.gz" \
                                     "$STACKINGDIR/reslice/reslice_histo_slice${ipad}.nii.gz" \
                                      $STACKINGDIR/accum/${tx}_Affine.txt \
                                  -R "$GRAYDIR/${ref}.nii.gz" 

  $ANTSDIR/WarpImageMultiTransform 2 "$MASKDIR/${mask}.nii.gz" \
                                     "$STACKINGDIR/reslice/mask/reslice_histo_mask_slice${ipad}.nii.gz" \
                                      $STACKINGDIR/accum/${tx}_Affine.txt \
                                  -R "$GRAYDIR/${ref}.nii.gz" --use-NN

elif (( ${LINEAR_RECON_ANTS} == 2 )); then
	# using FSL
	$FSLDIR/flirt -in   "$GRAYDIR/${mov}.nii.gz" \
    	          -ref  "$GRAYDIR/${ref}.nii.gz" \
                -out  "$STACKINGDIR/reslice/reslice_histo_slice${ipad}.nii.gz" \
            	  -init "$STACKINGDIR/accum/${tx}.mat" \
	              -2D -applyxfm

	# Reslice the mask 
	$FSLDIR/flirt -in   "$MASKDIR/${mov}_mask.nii.gz" \
    	          -ref  "$GRAYDIR/${ref}.nii.gz" \
                -out  "$STACKINGDIR/reslice/mask/reslice_histo_mask_slice${ipad}.nii.gz" \
            	  -init "$STACKINGDIR/accum/${tx}.mat" \
	              -2D -applyxfm
fi

