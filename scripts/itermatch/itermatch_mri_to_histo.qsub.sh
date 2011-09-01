#!/bin/bash
#$ -cwd -S /bin/sh

# Set up the script environment
source ../common.sh

# Define the locations of the images
HISTO_INDIR=$1
HISTO_INNAME=$2
MRI_INDIR=$3
MRI_INNAME=$4
MRILABEL_INDIR=$5 
MRILABEL_INNAME=$6
MRI_OUTDIR=$7
MRI_OUTNAME=$8
iter=$9
MRI_INIT_TX=${10}

mkdir -p $MRI_OUTDIR/tx
mkdir -p $MRI_OUTDIR/label
mkdir -p $MRI_OUTDIR/slices
mkdir -p $MRI_OUTDIR/slices/label

echo "Align MRI to histology volume..."

if [[ ${M2H_PROG} == "ANTS_LINEAR" ]]; then
  if (( ${iter} == 1 )); then
   $ANTSDIR/ANTS 3 -m MI["$HISTO_INDIR/${HISTO_INNAME}.nii.gz","$MRI_INDIR/${MRI_INNAME}.nii.gz",1,32] \
                    -o "$MRI_OUTDIR/tx/${MRI_OUTNAME}_" \
                    -a $M2HDIR/init/tx/init_Affine.txt  \
                    -i 0 \
                    --affine-metric-type MI \
                    --MI-option 32x16000 \
                    --number-of-affine-iterations 10000x10000x10000 

  else
# initialize with previous iteration's affine transformation, but use original MR image
    $ANTSDIR/ANTS 3 -m MI["$HISTO_INDIR/${HISTO_INNAME}.nii.gz","$MRI_INDIR/${MRI_INNAME}.nii.gz",1,32] \
                    -o "$MRI_OUTDIR/tx/${MRI_OUTNAME}_" \
                    -a ${MRI_INIT_TX} \
                    -i 0 \
                    --affine-metric-type MI \
                    --MI-option 32x16000 \
                    --number-of-affine-iterations 10000x10000x10000
  fi
 $ANTSDIR/WarpImageMultiTransform 3 "$MRI_INDIR/${MRI_INNAME}.nii.gz" \
                                     "$MRI_OUTDIR/${MRI_OUTNAME}.nii.gz" \
                                     "$MRI_OUTDIR/tx/${MRI_OUTNAME}_Affine.txt" \
                                  -R "$HISTO_INDIR/${HISTO_INNAME}.nii.gz"  
                                  

  $ANTSDIR/WarpImageMultiTransform 3 "$MRILABEL_INDIR/${MRILABEL_INNAME}.nii.gz" \
                                     "$MRI_OUTDIR/label/${MRI_OUTNAME}_label.nii.gz" \
                                     "$MRI_OUTDIR/tx/${MRI_OUTNAME}_Affine.txt" \
                                  -R "$HISTO_INDIR/${HISTO_INNAME}.nii.gz" --use-NN

elif [[ ${M2H_PROG} == "FSL_LINEAR" ]]; then
  if ((${iter} == 1)); then
    $FSLDIR/flirt -ref  "$HISTO_INDIR/${HISTO_INNAME}.nii.gz" \
                  -in   "$MRI_INDIR/${MRI_INNAME}.nii.gz" \
                  -out  "$MRI_OUTDIR/${MRI_OUTNAME}.nii.gz" \
                  -omat "$MRI_OUTDIR/tx/${MRI_OUTNAME}.mat" \
                  -dof 9 \
                  -nosearch \
                  -cost normmi \
                  -searchcost normmi \
                  -verbose 3 # > "$OUTPUTDIR/FLIRT_affine_mri2histo.txt"

#              -refweight "$LINEARDIR/volume/reslice_histo_mask.nii.gz" \
#              -inweight  "$MRIDIR/NDRI64415_right_blockF.nii.gz" \

    $FSLDIR/flirt -ref  "$HISTO_INDIR/${HISTO_INNAME}.nii.gz" \
                  -in   "$MRILABEL_INDIR/${MRILABEL_INNAME}.nii.gz" \
                  -out  "$MRI_OUTDIR/label/${MRI_OUTNAME}_label.nii.gz" \
                  -applyxfm -init "$MRI_OUTDIR/tx/${MRI_OUTNAME}.mat" \
                  -interp nearestneighbour \
                  -verbose 3 # > "$OUTPUTDIR/FLIRT_affine_mrilabel2histo.txt"

  else
    $FSLDIR/flirt -ref  "$HISTO_INDIR/${HISTO_INNAME}.nii.gz" \
                  -in   "$MRI_INDIR/${MRI_INNAME}.nii.gz" \
                  -out  "$MRI_OUTDIR/${MRI_OUTNAME}.nii.gz" \
                  -init "${MRI_INIT_TX}"  \
                  -omat "$MRI_OUTDIR/tx/${MRI_OUTNAME}.mat" \
                  -dof 9 \
                  -nosearch \
                  -cost normmi \
                  -searchcost normmi \
                  -verbose 3 # > "$OUTPUTDIR/FLIRT_affine_mri2histo.txt"

#              -refweight "$LINEARDIR/volume/reslice_histo_mask.nii.gz" \
#              -inweight  "$MRIDIR/NDRI64415_right_blockF.nii.gz" \

    $FSLDIR/flirt -ref  "$HISTO_INDIR/${HISTO_INNAME}.nii.gz" \
                  -in   "$MRILABEL_INDIR/${MRILABEL_INNAME}.nii.gz" \
                  -out  "$MRI_OUTDIR/label/${MRI_OUTNAME}_label.nii.gz" \
                  -applyxfm -init "$MRI_OUTDIR/tx/${MRI_OUTNAME}.mat" \
                  -interp nearestneighbour \
                  -verbose 3 # > "$OUTPUTDIR/FLIRT_affine_mrilabel2histo.txt"
  fi
fi

# NOTE: we used ANTS for 3D affine registration of block F, but used FSL for 3D affine registration of block E
# We should add an option of deformable registration of MRI to histology at this point

# Here we cut the mri data
echo "Making MRI slices"

$PROGDIR/ConvertImageSeries $MRI_OUTDIR/slices ${MRI_OUTNAME}_slice%05d.nii.gz $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz 
$PROGDIR/ConvertImageSeries $MRI_OUTDIR/slices/label ${MRI_OUTNAME}_label_slice%05d.nii.gz \
$MRI_OUTDIR/label/${MRI_OUTNAME}_label.nii.gz 

