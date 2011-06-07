#!/bin/bash
# Set up the script environment
source ../common.sh

HISTO_DIR="$H2MDIR/iter${H2M_NITER}/reslice"
HISTOMASK_DIR="$H2MDIR/iter${H2M_NITER}/reslice/mask"
HISTO_NAME="inplane_H2M_slice"
HISTOMASK_NAME="inplane_H2M_mask_slice"
TXPATH="$DEFORMDIR/tx"
VOLUMEPATH="$DEFORMDIR/volume"

# Make sure directories exist
mkdir -p $TRG_SLICEPATH
mkdir -p $TRGLABEL_SLICEPATH
mkdir -p $TXPATH
mkdir -p $VOLUMEPATH
mkdir -p $VOLUMEPATH/label

# make sure directories are clean
# rm -rf $TRG_SLICEPATH/*.*
# rm -rf $TRGLABEL_SLICEPATH/*.*
# rm -rf $TXPATH/*.*
# rm -rf $VOLUMEPATH/*.*

# Submit a job for every image in the source directory
echo "Registering MR slices to corresponding histology slices"

nslices=`ls -1 $MRI_SLICEPATH | grep "\.nii\.gz" | wc -l`
echo $nslices

for ((k=0;k<nslices;k++))
do
	kpad=`printf %05d $k`

   qsub -N "deform${k}" -o $OUTPUTDIR -e $ERRORDIR mri_to_histo_2D.qsub.sh \
   $HISTO_SLICEPATH $HISTOMASK_SLICEPATH $HISTO_SLICENAME $HISTOMASK_SLICENAME \
   $MRI_SLICEPATH $MRILABEL_SLICEPATH $MRI_SLICENAME $MRILABEL_SLICENAME \
   $TRG_SLICEPATH $TRGLABEL_SLICEPATH $TXPATH ${kpad}

done

qblock

echo "Building a 3D volume [ $H2MDIR/volume/inplane_MR_to_histo.nii.gz ]"

# Get the information for spacing
spacingx=$HSPACEX
spacingy=$HSPACEY
spacingz=$HSPACEZ
orient=${HISTO_ORIENT}
flip=${HISTO_FLIP}

if [ -n "$flip" ] 
then
	flip_option="-flip $flip"
else
	flip_option=''
fi

$PROGDIR/imageSeriesToVolume -o "$VOLUMEPATH/inplane_M2H.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $TRG_SLICEPATH/*.nii.gz`

$PROGDIR/imageSeriesToVolume -o "$VOLUMEPATH/label/inplane_M2H_label.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $TRGLABEL_SLICEPATH/*.nii.gz`

$C3DDIR/c3d $VOLUMEPATH/inplane_M2H.nii.gz \
$flip_option \
-pa $orient \
-orient RAI -origin 0x0x0mm \
-o "$VOLUMEPATH/inplane_M2H_oriented.nii.gz" 

$C3DDIR/c3d $VOLUMEPATH/label/inplane_M2H_label.nii.gz \
$flip_option \
-pa $orient \
-orient RAI -origin 0x0x0mm \
-o "$VOLUMEPATH/label/inplane_M2H_label_oriented.nii.gz" 

