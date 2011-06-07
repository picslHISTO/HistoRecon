source ../common.sh

HISTOMASK_INDIR="$STACKINGDIR/reslice/mask/area/volume"
HISTOMASK_INNAME="histo_mask"
MRIMASK_INDIR="$DATADIR/input/mri_oriented/mask/slices/area/volume"
MRIMASK_INNAME="mri_mask"
MRI_OUTDIR="$MRIMASK_INDIR/output"
mkdir -p $MRI_OUTDIR/tx
mkdir -p $MRI_OUTDIR/volume

$C3DDIR/c3d $HISTOMASK_INDIR/${HISTOMASK_INNAME}.nii.gz -resample 256x256x512vox $HISTOMASK_INDIR/${HISTOMASK_INNAME}_resample.nii.gz

$ANTSDIR/ANTS 3 -m MI["$HISTOMASK_INDIR/${HISTOMASK_INNAME}_resample.nii.gz","$MRIMASK_INDIR/${MRIMASK_INNAME}.nii.gz",1,32] \
                    -o "$MRI_OUTDIR/tx/area_" \
                    -i 0 \
                    --affine-metric-type MI \
                    --MI-option 8x32000 \
                    --number-of-affine-iterations 10000x10000


$ANTSDIR/WarpImageMultiTransform 3 "$MRIMASK_INDIR/${MRIMASK_INNAME}.nii.gz" \
                                   "$MRI_OUTDIR/volume/mri_mask.nii.gz" \
                                   "$MRI_OUTDIR/tx/area_Affine.txt" \
                                -R "$HISTOMASK_INDIR/${HISTOMASK_INNAME}_resample.nii.gz"






