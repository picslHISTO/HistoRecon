#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh
source ../common.sh

# Read command line parameters. These are the names of the images without filename suffix
fixed=$1  # fixed image
moving=$2  # moving image
mask=$3 # fixed mask
dim=2
its=10000x10000x10000x0

# Define the transformation file names
tx="linear_fix_${fixed}_mov_${moving}"
tx_inv="linear_fix_${moving}_mov_${fixed}"

# Perform 2D registration of slices
echo "linear registration of ${fixed} (fixed) and ${moving} (moving)..."
# while the registration is moving to fixed, the transformation is from moving to fixed

# this may be used to directly calculate the measure 
# cat $OUTPUTDIR/linear_${mov2fix}.txt | sed -e "s/final measure value (MMI): rval = //g" \
#       > $STACKINGDIR/metric/.txt

if [[ ${STACKING_RECON_PROG} == "ANTS" ]]; then
  # using ANTS linear 
  if [[ ${STACKING_RECON_DOF} == 6 ]]; then
    echo "2D Affine registration (DOF = 6)"
     $ANTSDIR/antsRegistration -d $dim \
                      -r [ $GRAYDIR/${fixed}.nii.gz, $GRAYDIR/${moving}.nii.gz, 1 ] \
                      -m CC[ $GRAYDIR/${fixed}.nii.gz, $GRAYDIR/${moving}.nii.gz, 1 ] \
                      -t affine[ 0.2 ] \
                      -c [$its,1.e-8,20]  \
                      -s 4x2x1vox  \
                      -f 6x4x2 -l 1 -o [$STACKINGDIR/tx/$tx] 
     # > "$OUTPUTDIR/linear_${tx}.txt"

  elif (( ${STACKING_RECON_DOF} == 3 )); then
    echo "2D Rigid registration (DOF = 3)"
     $ANTSDIR/antsRegistration -d $dim \
                      -r [ $GRAYDIR/${fixed}.nii.gz, $GRAYDIR/${moving}.nii.gz, 1 ]  \
                      -m CC[ $GRAYDIR/${fixed}.nii.gz, $GRAYDIR/${moving}.nii.gz, 1 ] \
                      -t rigid[ 0.2 ] \
                      -c [$its, 1.e-8, 20]  \
                      -s 4x2x1vox  \
                      -f 6x4x2 -l 1 -o [$STACKINGDIR/tx/${tx}_] 
     # > "$OUTPUTDIR/linear_${tx}.txt"
  fi

  $ANTSDIR/antsApplyTransforms -d $dim -i $GRAYDIR/${moving}.nii.gz \
                               -r $GRAYDIR/${fixed}.nii.gz -n linear \
                               -t $STACKINGDIR/tx/${tx}_0GenericAffine.mat \
                               -o $STACKINGDIR/warp/${tx}.nii.gz

elif [[ ${STACKING_RECON_PROG} == "FSL" ]]; then
  # FSL linear
  # This command also warps the input image
  $FSLDIR/flirt -ref "$GRAYDIR/${fixed}.nii.gz" \
                -in  "$GRAYDIR/${moving}.nii.gz" \
                -refweight "$MASKDIR/${fixed}_mask.nii.gz" \
                -inweight "$MASKDIR/${moving}_mask.nii.gz" \
                -out "$STACKINGDIR/warp/${tx}.nii.gz" \
                -omat "$STACKINGDIR/tx/${tx}.mat" \
                -cost normmi \
                -2D -schedule "$SCHDIR/sch2D_${STACKING_RECON_DOF}dof" \
                -verbose 2 # > "$OUTPUTDIR/linear_${tx}.txt"
 
  # Compute the inverse transform
  $FSLDIR/convert_xfm -inverse "$STACKINGDIR/tx/${tx}.mat" \
                      -omat    "$STACKINGDIR/tx/${tx_inv}.mat"                     


# For the time being, we will not use the ANTS deformable to do the stacking
# elif [[ ${STACKING_RECON_PROG} == "ANTS_DEFORMABLE" ]]; then
#   # deformable ANTS
#   $ANTSDIR/ANTS 2 \
#                -m MI["$GRAYDIR/${fixed}.nii.gz","$GRAYDIR/${moving}.nii.gz",1,32] \
#                -t SyN[0.25] \
#                -r Gauss[1] \
#                -o "$STACKINGDIR/tx/${fix2mov}_" \
#                -x "$MASKDIR/${mask}.nii.gz" \
#                -i 100x100 \
#                --affine-metric-type MI \
#                --MI-option 32x10000 \
#                --use-Histogram-Matching \
#                --number-of-affine-iterations 10000x10000x10000 \
#                > "$OUTPUTDIR/linear_${fix2mov}.txt"
# 
#   $ANTSDIR/WarpImageMultiTransform 2 "$GRAYDIR/${moving}.nii.gz" \
#                                      "$STACKINGDIR/warp/${fix2mov}.nii.gz" \
#                                      "$STACKINGDIR/tx/${fix2mov}_Warp.nii.gz" \
#                                      "$STACKINGDIR/tx/${fix2mov}_Affine.txt" \
#                                   -R "$GRAYDIR/${fixed}.nii.gz"
fi


# Get the mutual information and normalized correlation similarity metrics value between the images
# before and after transformation

#   min normalized correlation (ncor) metric: -1.0 (best match)
#   max normalized mutual information (nmi) metric: 2.0 (best match)
echo "Compute metric between ${fixed} and ${moving} and ${tx}..."

$C3DDIR/c2d "$GRAYDIR/${fixed}.nii.gz" "$STACKINGDIR/warp/${tx}.nii.gz" -ncor \
            | grep "NCOR" | tail -n 1 | sed -e "s/.*= -//" \
            > "$STACKINGDIR/metric/metric_ncor_${tx}.txt"

