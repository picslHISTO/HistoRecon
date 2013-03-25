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

fix="$HISTO_INDIR/${HISTO_INNAME}.nii.gz"
mov="$MRI_INDIR/${MRI_INNAME}.nii.gz"
mov_label="$MRILABEL_INDIR/${MRILABEL_INNAME}.nii.gz"
target="$MRI_OUTDIR/${MRI_OUTNAME}.nii.gz"
target_label="$MRI_OUTDIR/label/${MRI_OUTNAME}_label.nii.gz"
its=10000x10000x10000
tx="$MRI_OUTDIR/tx/${MRI_OUTNAME}"

mkdir -p $MRI_OUTDIR/tx
mkdir -p $MRI_OUTDIR/label
mkdir -p $MRI_OUTDIR/slices
mkdir -p $MRI_OUTDIR/slices/label

echo "Align MRI to histology volume..."

if [[ ${M2H_PROG} == "ANTS_LINEAR" ]]; then
  if (( ${iter} == 1 )); then
   # $ANTSDIR/ANTS 3 -m MI["$HISTO_INDIR/${HISTO_INNAME}.nii.gz","$MRI_INDIR/${MRI_INNAME}.nii.gz",1,32] \
   #                  -o "$MRI_OUTDIR/tx/${MRI_OUTNAME}_" \
   #                  -a $M2HDIR/init/tx/init_Affine.txt  \
   #                  -i 0 \
   #                  --affine-metric-type MI \
   #                  --MI-option 32x16000 \
   #                  --number-of-affine-iterations 10000x10000x10000 

     $ANTSDIR/antsRegistration -d 3 \
                      -r [ $fix, $mov, 1] \
                      -m MI[ $fix, $mov, 1, 32 ]  \
                      -q $M2HDIR/init/tx/init_Affine.txt \
                      -t affine[ 0.2 ] \
                      -c [$its,1.e-8,20]  \
                      -s 4x2x1vox  \
                      -f 6x4x2 -l 1 -o [ ${tx}_ ] 
  else
# initialize with previous iteration's affine transformation, but use original MR image
     $ANTSDIR/antsRegistration -d 3 \
                      -r [ $fix, $mov, 1] \
                      -m MI[ $fix, $mov, 1, 32 ]  \
                      -q ${MRI_INIT_TX} \
                      -t affine[ 0.2 ] \
                      -c [$its,1.e-8,20]  \
                      -s 4x2x1vox  \
                      -f 6x4x2 -l 1 -o [ ${tx}_ ] 
   fi

  $ANTSDIR/antsApplyTransforms -d 3 -i $mov \
                               -r $fix -n linear \
                               -t ${tx}_0GenericAffine.mat \
                               -o $target

  $ANTSDIR/antsApplyTransforms -d 3 -i $mov_label \
                               -r $fix -n NearestNeighbor \
                               -t ${tx}_0GenericAffine.mat \
                               -o $target_label

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

$PROGDIR/ConvertImageSeries -o $MRI_OUTDIR/slices/${MRI_OUTNAME}_slice%05d.nii.gz \
                            -in $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz 
$PROGDIR/ConvertImageSeries -o $MRI_OUTDIR/slices/label/${MRI_OUTNAME}_label_slice%05d.nii.gz \
                            -in $MRI_OUTDIR/label/${MRI_OUTNAME}_label.nii.gz 

