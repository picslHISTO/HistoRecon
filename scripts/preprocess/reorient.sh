#!/bin/bash
# ==============================
# get spacing of the image
# from $GRAYDIR to $GRAYDIR (using the same 
#  filename in the same directory)
# also flip/permute axis of 3D Histo image
# save in  VOLUMEPATH=$DATADIR/input/histo/volume
# this is for visualization only
# and also flip/permute axis of 3D MRI 
# image in the reverse order
# save in MRI_OUTDIR="$DATADIR/input/mri_oriented
# ==============================

source ../common.sh
spacingx=$RESPACEX
spacingy=$RESPACEY
spacingz=$HSPACEZ

INPUTPATH=$GRAYDIR
OUTPUTPATH=$DATADIR/input/histo/tmp
VOLUMEPATH=$DATADIR/input/histo/volume

# make sure the directories exist 
mkdir -p $OUTPUTPATH
mkdir -p $VOLUMEPATH

# make sure the directories are clean
num=`ls -1 $INPUTPATH | wc -l`
REFIMG=`ls -1 $INPUTPATH | grep "\.nii\.gz" | head -n $((num/2)) | tail -n 1 | sed "s/\.nii\.gz//g"`
rm -rf $OUTPUTPATH/*.*
rm -rf $VOLUMEPATH/*.*

echo "Set spacing and transform all the histology image to a common space"

for img in `ls -1 $INPUTPATH | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//g"`
do
  exe "reorient-$img" 1 reorient.qsub.sh \
  $img $INPUTPATH $OUTPUTPATH $REFIMG
done

qblock "reorient"

$PROGDIR/imageSeriesToVolume -o "$VOLUMEPATH/volume.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $OUTPUTPATH/*.nii.gz | sort`

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $VOLUMEPATH/volume.nii.gz \
        $VOLUMEPATH/volume.nii.gz \
        $HISTO_REV_ORIENT 

$C3DDIR/c3d $VOLUMEPATH/volume.nii.gz \
-orient RAI -origin 0x0x0mm \
-o $VOLUMEPATH/volume.nii.gz

echo "reorient the mri images"

MRI_OUTDIR="$DATADIR/input/mri_oriented"
MRI_OUTNAME="mri"
MRILABEL_OUTDIR="$DATADIR/input/mri_oriented/label"
MRILABEL_OUTNAME="mri_label"
MRIMASK_OUTDIR="$DATADIR/input/mri_oriented/mask"
MRIMASK_OUTNAME="mri_mask"
mkdir -p $MRI_OUTDIR
mkdir -p $MRILABEL_OUTDIR
mkdir -p $MRIMASK_OUTDIR

cp ${MRI_WAXHOLM_FILE} $MRI_OUTDIR/${MRI_OUTNAME}_oriented.nii.gz
cp ${MRILABEL_WAXHOLM_FILE} $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}_oriented.nii.gz
$C3DDIR/c3d ${MRILABEL_WAXHOLM_FILE} \
            -thresh 1 inf 1 0 \
            -o $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}_oriented.nii.gz

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $MRI_OUTDIR/${MRI_OUTNAME}_oriented.nii.gz \
        $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz \
        $HISTO_ORIENT
                                         
$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}_oriented.nii.gz \
        $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}.nii.gz \
        $HISTO_ORIENT

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}_oriented.nii.gz \
        $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}.nii.gz \
        $HISTO_ORIENT


$C3DDIR/c3d $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz 

$C3DDIR/c3d $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}.nii.gz 

$C3DDIR/c3d $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o $MRIMASK_OUTDIR/${MRIMASK_OUTNAME}.nii.gz 


