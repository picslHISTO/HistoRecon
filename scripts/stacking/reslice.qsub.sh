#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

# Read command line parameters
mov=$1
ref=$2
mask=$3
ipad=$4
dim=2


tx="linear_fix_${ref}_mov_${mov}"

# Reslice the image
if [[ ${STACKING_RECON_PROG} == "ANTS" ]]; then
	# using ANTS (valid for both affine and deformable registration,
  # since accumulation file contains the affine and deformable transformations

  $ANTSDIR/antsApplyTransforms -d $dim -i $GRAYDIR/${mov}.nii.gz \
                               -r $GRAYDIR/${ref}.nii.gz -n linear \
                               -t $STACKINGDIR/accum/${tx}_0GenericAffine.mat \
                               -o $STACKINGDIR/reslice/reslice_histo_slice${ipad}.nii.gz

  $ANTSDIR/antsApplyTransforms -d $dim -i $MASKDIR/${mask}.nii.gz \
                               -r $GRAYDIR/${ref}.nii.gz -n NearestNeighbor \
                               -t $STACKINGDIR/accum/${tx}_0GenericAffine.mat \
                               -o $STACKINGDIR/reslice/mask/reslice_histo_mask_slice${ipad}.nii.gz 

elif [[ ${STACKING_RECON_PROG} == "FSL" ]]; then
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

