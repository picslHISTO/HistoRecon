#!/bin/bash
# Set up the script environment
source ../common.sh

# input directories
HISTO_SLICEDIR="$STACKINGDIR/reslice"
HISTO_SLICENAME="reslice_histo_slice"

MRI_INDIR="$DATADIR/input/mri_oriented"
MRI_INNAME="mri"
MRI_SLICEDIR="$DATADIR/input/mri_oriented_slices"
MRI_SLICENAME="mri_slice_"

MRIMASK_INDIR="$DATADIR/input/mri_oriented/mask"
MRIMASK_INNAME="mri_mask"
MRIMASK_SLICEDIR="$DATADIR/input/mri_oriented_slices/mask"
MRIMASK_SLICENAME="mri_mask_slice_"

# making directories 
mkdir -p $MRI_SLICEDIR
mkdir -p $MRIMASK_SLICEDIR

mkdir -p $MANUALDIR/tx
mkdir -p $MANUALDIR/mri/slices
mkdir -p $MANUALDIR/mri/slices_out
mkdir -p $MANUALDIR/mri/volume
mkdir -p $MANUALDIR/mri/volume_out
mkdir -p $MANUALDIR/histo/slices
mkdir -p $MANUALDIR/histo/slices_out
mkdir -p $MANUALDIR/histo/volume
mkdir -p $MANUALDIR/histo/volume_out

# remove old files in the directory
rm -rf  $MANUALDIR/tx/*.*
rm -rf  $MANUALDIR/mri/slices/*.*
rm -rf  $MANUALDIR/mri/slices_out/*.*
rm -rf  $MANUALDIR/mri/volume/*.*
rm -rf  $MANUALDIR/mri/volume_out/*.*
rm -rf  $MANUALDIR/histo/slices/*.*
rm -rf  $MANUALDIR/histo/slices_out/*.*
rm -rf  $MANUALDIR/histo/volume/*.*
rm -rf  $MANUALDIR/histo/volume_out/*.*

##########################
# 1.generate MRI slices
##########################
echo "Make MRI slices in the input directory"
$PROGDIR/ConvertImageSeries -o "$MRI_SLICEDIR/${MRI_SLICENAME}%05d.nii.gz" \
                            -in "$MRI_INDIR/${MRI_INNAME}.nii.gz" 



num_of_histo=`echo "${MANUAL_HISTO_INDEX_END} - ${MANUAL_HISTO_INDEX_START} + 1" | bc -l`
num_of_mri=`echo "${MANUAL_MRI_INDEX_END} - ${MANUAL_MRI_INDEX_START} + 1" | bc -l`
echo "there are "$num_of_histo " histology slices."
echo "there are "$num_of_mri "MRI slices"

# get the spacing info of MRI slices 
mri_spacingz=`$C3DDIR/c3d $MRI_INDIR/${MRI_INNAME}.nii.gz -info-full \
  | grep "Voxel Spacing" | sed "s/.*\[//g" | sed "s/\].*//g" | cut -d "," -f 3`

# make the spacing of histology match that in the mri 
histo_spacingz=`echo "$mri_spacingz * $num_of_mri / $num_of_histo" | bc -l`

echo "Spacing in z direction of the histology volume is " $histo_spacingz

for ((jj=$MANUAL_HISTO_INDEX_START ; jj<=$MANUAL_HISTO_INDEX_END; jj++)); do 
  jj_full=`printf %05d $jj`
  cp ${HISTO_SLICEDIR}/${HISTO_SLICENAME}${jj_full}.nii.gz ${MANUALDIR}/histo/slices
done

for ((jj=$MANUAL_MRI_INDEX_START; jj<=$MANUAL_MRI_INDEX_END; jj++)); do 
  jj_full=`printf %05d $jj`
  cp ${MRI_SLICEDIR}/${MRI_SLICENAME}${jj_full}.nii.gz ${MANUALDIR}/mri/slices
done

##########################
# 2. Resample MRI volume
##########################
echo "making the mri block volume"
$PROGDIR/ConvertImageSeries -o ${MANUALDIR}/mri/volume/volume.nii.gz \
                            -sz $mri_spacingz \
                            -in `ls ${MANUALDIR}/mri/slices/*.nii.gz`

# resample the MRI volume 
dim=(`$C3DDIR/c3d ${MANUALDIR}/mri/volume/volume.nii.gz -info | sed "s/^.*dim = \[/ /g" | sed "s/\].*//g" | sed "s/\,//g"`)

echo "resample the mri block volume"
$C3DDIR/c3d ${MANUALDIR}/mri/volume/volume.nii.gz \
            -resample ${dim[0]}x${dim[1]}x${num_of_histo} \
            -o ${MANUALDIR}/mri/volume_out/volume.nii.gz

echo "making the mri slices"
$PROGDIR/ConvertImageSeries -o ${MANUALDIR}/mri/slices_out/mri_%05d.nii.gz \
                            -in ${MANUALDIR}/mri/volume_out/volume.nii.gz 

###############################
# 3. Register histology to MRI
###############################

histo_img=(`ls ${MANUALDIR}/histo/slices | sed "s/\.nii\.gz//g"`)
mri_img=(`ls ${MANUALDIR}/mri/slices_out | sed "s/\.nii\.gz//g"`)

for (( jj=0; jj < $num_of_histo; jj++ )); do
  exe "mri_histo_manual" 1 manMatch.qsub.sh \
  ${histo_img[$jj]} ${mri_img[$jj]}
done

qblock "mri_histo_manual"

echo "making the new histology volume"

$PROGDIR/ConvertImageSeries -o ${MANUALDIR}/histo/volume_out/volume.nii.gz \
                            -sz $histo_spacingz \
                            -in `ls ${MANUALDIR}/histo/slices_out/*.nii.gz`

