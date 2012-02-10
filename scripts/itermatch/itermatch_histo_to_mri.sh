#!/bin/bash
# Set up the script environment
source ../common.sh

MRI_INDIR=$1
MRI_INNAME=$2
HISTO_SLICE_INDIR=$3
HISTO_SLICE_INNAME=$4
HISTOMASK_SLICE_INDIR=$5
HISTOMASK_SLICE_INNAME=$6
HISTO_OUTDIR=$7
HISTO_OUTNAME=$8

MRISLICE_DIR=$MRI_INDIR/slices
MRISLICE_NAME=${MRI_INNAME}_slice


# Make sure directories exist
mkdir -p $HISTO_OUTDIR/reslice
mkdir -p $HISTO_OUTDIR/reslice/mask
mkdir -p $HISTO_OUTDIR/tx
mkdir -p $HISTO_OUTDIR/tx_smooth
mkdir -p $HISTO_OUTDIR/volume
mkdir -p $HISTO_OUTDIR/volume/mask

echo python smooth_h2m_transforms.py $H2M_SMOOTH_SIGMA $HISTO_OUTDIR/tx $HISTO_OUTDIR/tx_smooth
# Submit a job for every image in the source directory
nslices=`ls -1 ${HISTO_SLICE_INDIR}/*.nii.gz | wc -l`

echo "Registering histology slices to corresponding MR slices"
for ((k=0; k < ${nslices}; k=k+1))
do
	kpad=`printf "%05d" $k`	
  exe "H2M_reg_${k}" 1 itermatch_histo_to_mri_reg.qsub.sh \
  $kpad $MRISLICE_DIR $MRISLICE_NAME \
  $HISTO_SLICE_INDIR $HISTO_SLICE_INNAME $HISTOMASK_SLICE_INDIR $HISTOMASK_SLICE_INNAME $HISTO_OUTDIR
done

qblock "H2M_reg"
  
# Smooth the rigid transform
echo "smoothing the rigid transform"
python smooth_h2m_transforms.py $H2M_SMOOTH_SIGMA $HISTO_OUTDIR/tx $HISTO_OUTDIR/tx_smooth

for ((k=0; k < ${nslices}; k=k+1))
do
	kpad=`printf "%05d" $k`	
  exe "H2M_warp_${k}" 1 itermatch_histo_to_mri_warp.qsub.sh \
  $kpad $MRISLICE_DIR $MRISLICE_NAME \
  $HISTO_SLICE_INDIR $HISTO_SLICE_INNAME $HISTOMASK_SLICE_INDIR $HISTOMASK_SLICE_INNAME $HISTO_OUTDIR
done

qblock "H2M_warp" 

# Compute a whole volume
echo "Building a 3D volume [ $HISTO_OUTDIR/volume/histo_to_mri.nii.gz ]"

# here we read the spacing information 


$PROGDIR/imageSeriesToVolume -o "$HISTO_OUTDIR/volume/histo_to_mri.nii.gz" \
                             -sx $spacingx_orient -sy $spacingy_orient -sz $spacingz_orient \
                             -i `ls -1 $HISTO_OUTDIR/reslice/*.nii.gz`

$PROGDIR/imageSeriesToVolume -o "$HISTO_OUTDIR/volume/mask/histo_to_mri_mask.nii.gz" \
                             -sx $spacingx_orient -sy $spacingy_orient -sz $spacingz_orient \
                             -i `ls -1 $HISTO_OUTDIR/reslice/mask/*.nii.gz`
echo "Building a 3D volume" 


spacingx=$RESPACEX
spacingy=$RESPACEY
spacingz=$HSPACEZ

$PROGDIR/imageSeriesToVolume -o "$HISTO_OUTDIR/volume/histo_to_mri.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $HISTO_OUTDIR/reslice/*.nii.gz`

$PROGDIR/imageSeriesToVolume -o "$HISTO_OUTDIR/volume/mask/histo_to_mri_mask.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $HISTO_OUTDIR/reslice/mask/*.nii.gz`

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $HISTO_OUTDIR/volume/histo_to_mri.nii.gz \
        $HISTO_OUTDIR/volume/histo_to_mri_oriented.nii.gz \
        $HISTO_REV_ORIENT

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $HISTO_OUTDIR/volume/mask/histo_to_mri_mask.nii.gz \
        $HISTO_OUTDIR/volume/mask/histo_to_mri_mask_oriented.nii.gz \
        $HISTO_REV_ORIENT

$C3DDIR/c3d $HISTO_OUTDIR/volume/histo_to_mri_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o "$HISTO_OUTDIR/volume/histo_to_mri_oriented.nii.gz" \

$C3DDIR/c3d $HISTO_OUTDIR/volume/mask/histo_to_mri_mask_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o "$HISTO_OUTDIR/volume/mask/histo_to_mri_mask_oriented.nii.gz" \

