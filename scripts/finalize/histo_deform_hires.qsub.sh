#!/bin/sh
#$ -cwd -S /bin/sh
source ../common.sh

curr=$1
histodef_tx=$2

$ANTSDIR/WarpImageMultiTransform 2 \
				"$FINALDIR/histo_to_mri/reslice/orig/inplane_histo_to_MR_${curr}.nii.gz" \
				"$FINALDIR/deform/slices/orig/inplane_histo_to_MR_${curr}.nii.gz" \
			 -R "$FINALDIR/histo_to_mri/reslice/orig/inplane_histo_to_MR_${curr}.nii.gz" \
				`cat ${histodef_tx}`
