#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh
source ../common.sh

# Read command line parameters. These are the names of the images without filename suffix
fixed=$1  # fixed image
moving=$2  # moving image
mask=$3 # fixed mask

# Define the file names
mov2fix="linear_${moving}_to_${fixed}"
fix2mov="linear_${fixed}_to_${moving}"

# Perform 2D registration of slices
echo "3-parameter registration of ${moving} to ${fixed}..."

echo $fixed $moving $mov2fix


# question??? do we need this?
# This command also warps the input image
$ANTSDIR/ANTS 2 \
       -m MI["$GRAYDIR/${fixed}.nii.gz","$GRAYDIR/${moving}.nii.gz",1,32] \
       -o "$STACKINGDIR/tx/${mov2fix}_" \
       -x $MASKDIR/${mask}.nii.gz \
       -i 0 \
       --rigid-affine true \
       --affine-metric-type MI \
       --MI-option 32x10000 \
       --number-of-affine-iterations 10000x10000x10000x10000 \
       > "$OUTPUTDIR/linear_${mov2fix}.txt"

# this may used to directly calculate the measure 
# cat $OUTPUTDIR/linear_${mov2fix}.txt | sed -e "s/final measure value (MMI): rval = //g" \
#       > $STACKINGDIR/metric/.txt
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

if (( ${LINEAR_RECON_ANTS} == 0 )); then
  # using ANTS linear 
  if (( ${LINEAR_RECON_TRANS} == 6 )); then
    # use 2D affine transformations
    $ANTSDIR/ANTS 2 \
        -m MI["$GRAYDIR/${fixed}.nii.gz","$GRAYDIR/${moving}.nii.gz",1,32] \
        -o "$STACKINGDIR/tx/${mov2fix}_" \
        -i 0 \
        --affine-metric-type MI \
        --MI-option 32x10000 \
        --number-of-affine-iterations 10000x10000x10000 \
        > "$OUTPUTDIR/linear_${mov2fix}.txt"

        #### -x "$MASKDIR/${mask}.nii.gz" \
        #### --rigid-affine true \
        
  elif (( ${LINEAR_RECON_TRANS} == 3 )); then
    # use 2D rigid transformations
    $ANTSDIR/ANTS 2 \
        -m MI["$GRAYDIR/${fixed}.nii.gz","$GRAYDIR/${moving}.nii.gz",1,32] \
        -o "$STACKINGDIR/tx/${mov2fix}_" \
        -i 0 \
        --affine-metric-type MI \
        --MI-option 32x10000 \
        --number-of-affine-iterations 10000x10000x10000 \
        --rigid-affine true \
        > "$OUTPUTDIR/linear_${mov2fix}.txt"
  fi

  $ANTSDIR/WarpImageMultiTransform 2 "$GRAYDIR/${moving}.nii.gz" \
                                     "$STACKINGDIR/warp/${mov2fix}.nii.gz" \
                                     "$STACKINGDIR/tx/${mov2fix}_Affine.txt" \
                                  -R "$GRAYDIR/${fixed}.nii.gz"
                  
elif (( ${LINEAR_RECON_ANTS} == 1 )); then
  # deformable ANTS
  $ANTSDIR/ANTS 2 \
               -m MI["$GRAYDIR/${fixed}.nii.gz","$GRAYDIR/${moving}.nii.gz",1,32] \
               -t SyN[0.25] \
               -r Gauss[1] \
               -o "$STACKINGDIR/tx/${mov2fix}_" \
               -x "$MASKDIR/${mask}.nii.gz" \
               -i 100x100 \
               --affine-metric-type MI \
               --MI-option 32x10000 \
               --use-Histogram-Matching \
               --number-of-affine-iterations 10000x10000x10000 \
               > "$OUTPUTDIR/linear_${mov2fix}.txt"

  $ANTSDIR/WarpImageMultiTransform 2 "$GRAYDIR/${moving}.nii.gz" \
                                     "$STACKINGDIR/warp/${mov2fix}.nii.gz" \
                                     "$STACKINGDIR/tx/${mov2fix}_Warp.nii.gz" \
                                     "$STACKINGDIR/tx/${mov2fix}_Affine.txt" \
                                  -R "$GRAYDIR/${fixed}.nii.gz"

elif (( ${LINEAR_RECON_ANTS} == 2 )); then
  # FSL linear
  # This command also warps the input image
  $FSLDIR/flirt -ref "$GRAYDIR/${fixed}.nii.gz" \
                -in  "$GRAYDIR/${moving}.nii.gz" \
                -refweight "$MASKDIR/${fixed}_mask.nii.gz" \
                -inweight "$MASKDIR/${moving}_mask.nii.gz" \
                -out "$STACKINGDIR/warp/${mov2fix}.nii.gz" \
                -omat "$STACKINGDIR/tx/${mov2fix}.mat" \
                -cost normmi \
                -2D -schedule "$SCHDIR/sch2D_${LINEAR_RECON_TRANS}dof" \
                -verbose 2 # > "$OUTPUTDIR/linear_${mov2fix}.txt"
 
  # Compute the inverse transform
  $FSLDIR/convert_xfm -inverse "$STACKINGDIR/tx/${mov2fix}.mat" \
                      -omat    "$STACKINGDIR/tx/${fix2mov}.mat"                     
fi


# Get the mutual information and normalized correlation similarity metrics value between the images
# before and after transformation

#   min normalized correlation (ncor) metric: -1.0 (best match)
#   max normalized mutual information (nmi) metric: 2.0 (best match)
echo "Compute metric between ${fixed} and ${moving} and ${mov2fix}..."

$C3DDIR/c2d "$GRAYDIR/${fixed}.nii.gz" "$GRAYDIR/${moving}.nii.gz" -ncor \
            | grep "NCOR" | tail -n 1 | sed -e "s/.*= -//" \
            > "$STACKINGDIR/metric/metric_ncor_${mov2fix}.txt"
            
$C3DDIR/c2d "$GRAYDIR/${fixed}.nii.gz" "$STACKINGDIR/warp/${mov2fix}.nii.gz" -ncor \
            | grep "NCOR" | tail -n 1 | sed -e "s/.*= -//" \
            >> "$STACKINGDIR/metric/metric_ncor_${mov2fix}.txt"

