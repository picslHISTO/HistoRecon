#!/bin/bash
#$ -cwd -S /bin/bash
# Set up the script environment
source ../common.sh

# input directories
# NOTE: input mri is a 3D volume and input histo are slices
HISTOMASK_SLICE_INDIR="$STACKINGDIR/reslice/mask"
HISTOMASK_SLICE_INNAME="reslice_histo_mask_slice"
MRIMASK_INDIR="$DATADIR/input/mri_oriented/mask"
MRIMASK_INNAME="mri_mask"

# make the directories
MRI_DIR=$M2HDIR/init/mrimask
HISTO_DIR=$M2HDIR/init/histomask
TX_DIR=$M2HDIR/init/tx

mkdir -p $TX_DIR

mkdir -p $MRI_DIR/orig/slices
mkdir -p $MRI_DIR/half/slices
mkdir -p $MRI_DIR/half/volume
mkdir -p $MRI_DIR/area

mkdir -p $HISTO_DIR/orig/slices
mkdir -p $HISTO_DIR/half/slices
mkdir -p $HISTO_DIR/half/volume
mkdir -p $HISTO_DIR/area

# create a file to record the area of the each mask slices
logfile="area.txt"

# name for the mri slices
MRIMASK_SLICE="mrimask_slice"

##############################################
# 1. Record the area
##############################################

echo "recording histo mask slice area information ..."
# make sure the file is empty before running
rm -rf $HISTO_DIR/area/$logfile

# get the area of each histo mask 
nslice=`ls $HISTOMASK_SLICE_INDIR | grep "\.nii\.gz" | wc -l`
for (( i=0; i<$nslice; i++ ))
do 
  ipad=`printf %05d $i`
  echo $i `$C3DDIR/c3d $HISTOMASK_SLICE_INDIR/${HISTOMASK_SLICE_INNAME}${ipad}.nii.gz -voxel-sum` \
   >> $HISTO_DIR/area/$logfile
done

echo "making mri mask slices ..."
# create mri mask slices
$PROGDIR/ConvertImageSeries $MRI_DIR/orig/slices ${MRIMASK_SLICE}%05d.nii.gz $MRIMASK_INDIR/${MRIMASK_INNAME}.nii.gz 

echo "recording mri mask slice area information ..."
# make sure the file is empty before running
rm -rf $MRI_DIR/area/$logfile

# make a directory to record the data
nslice=`ls $MRI_DIR/orig/slices | grep "\.nii\.gz" | wc -l`
for ((i=0; i<$nslice; i++ ))
do 
  ipad=`printf %05d $i`
  echo $i `$C3DDIR/c3d $MRI_DIR/orig/slices/${MRIMASK_SLICE}${ipad}.nii.gz -voxel-sum` \
   >> $MRI_DIR/area/$logfile
done

##############################################
# 2. Create half volume
##############################################

###############
# for histology
###############
echo "creating histo half mask volume..."
array=(`cat $HISTO_DIR/area/$logfile | sort -nk4 | tail -n 1`)
nslice=`ls $HISTOMASK_SLICE_INDIR | grep "\.nii\.gz" | wc -l`

# get rid of the "0" at the front
num=`echo ${array[0]} | bc -l`


# copy the original slices over
for ((i=0;i<$num;i++))
do
  ipad=`printf %05d $i`
  cp $HISTOMASK_SLICE_INDIR/${HISTOMASK_SLICE_INNAME}${ipad}.nii.gz $HISTO_DIR/half/slices/histomask${ipad}.nii.gz
done

# create some blank slices
for ((i=$num;i<$nslice;i++))
do
  ipad=`printf %05d $i`
  $C3DDIR/c2d $HISTOMASK_SLICE_INDIR/${HISTOMASK_SLICE_INNAME}${ipad}.nii.gz -scale 0 -o $HISTO_DIR/half/slices/histomask${ipad}.nii.gz
done

$PROGDIR/imageSeriesToVolume -o "$HISTO_DIR/half/volume/histomask.nii.gz" \
                             -sx $HSPACEX -sy $HSPACEY -sz $HSPACEZ \
                             -i `ls -1 $HISTO_DIR/half/slices/*.nii.gz`

#########
# for mri 
#########
echo "creating mri half mask volume..."
# get the spacing for the original mri
array=(`cat $MRI_DIR/area/$logfile | sort -nk4 | tail -n 1`)
nslice=`ls $MRI_DIR/orig/slices | grep "\.nii\.gz" | wc -l`

# get rid of the "0" at the front
num=`echo ${array[0]} | bc -l`
# copy the original slices over
for ((i=0;i<$num;i++))
do
  ipad=`printf %05d $i`
  cp $MRI_DIR/orig/slices/${MRIMASK_SLICE}${ipad}.nii.gz $MRI_DIR/half/slices/mrimask${ipad}.nii.gz
done

# create some blank slices
for ((i=$num;i<$nslice;i++))
do
  ipad=`printf %05d $i`
  $C3DDIR/c2d $MRI_DIR/orig/slices/${MRIMASK_SLICE}${ipad}.nii.gz -scale 0 -o $MRI_DIR/half/slices/mrimask${ipad}.nii.gz
done

$PROGDIR/imageSeriesToVolume -o "$MRI_DIR/half/volume/mrimask.nii.gz" \
                             -sz 0.043 -sx 0.043 -sy 0.043\
                             -i `ls -1 $MRI_DIR/half/slices/*.nii.gz`


##############################################
# 3. Register mri to histo
##############################################

# resample the histo image to match up with the mri
$C3DDIR/c3d $HISTO_DIR/half/volume/histomask.nii.gz -resample 256x256x512vox -o $HISTO_DIR/half/volume/histomask_resample.nii.gz

# registration
$ANTSDIR/ANTS 3 -m MI["$HISTO_DIR/half/volume/histomask_resample.nii.gz","$MRI_DIR/half/volume/mrimask.nii.gz",1,32] \
                -o "$TX_DIR/init_" \
                -i 0 \
                --affine-metric-type MI \
                --MI-option 8x32000 \
                --number-of-affine-iterations 10000x10000

$ANTSDIR/WarpImageMultiTransform 3 "$MRI_DIR/half/volume/mrimask.nii.gz" \
                                   "$MRI_DIR/half/volume/mrimask_warped.nii.gz" \
                                   "$TX_DIR/init_Affine.txt"  \
                                -R "$HISTO_DIR/half/volume/histomask_resample.nii.gz"

