source ../common.sh

HISTOMASK_SLICE_INDIR="$STACKINGDIR/reslice/mask"
HISTOMASK_SLICE_INNAME="reslice_histo_mask_slice"
mkdir -p $HISTOMASK_SLICE_INDIR/area

# make a directory to record the data
logfile="area.txt"
rm -rf $HISTOMASK_SLICE_INDIR/area/$logfile

nslice=`ls $HISTOMASK_SLICE_INDIR | grep "\.nii\.gz" | wc -l`
for ((i=0; i<$nslice; i++ ))
do 
  ipad=`printf %05d $i`
  echo $ipad `$C3DDIR/c3d $HISTOMASK_SLICE_INDIR/${HISTOMASK_SLICE_INNAME}${ipad}.nii.gz -voxel-sum` \
   >> $HISTOMASK_SLICE_INDIR/area/$logfile
done

MRIMASK_INDIR="$DATADIR/input/mri_oriented/mask"
MRIMASK_INNAME="mri_mask"
mkdir -p $MRIMASK_INDIR/slices
mkdir -p $MRIMASK_INDIR/slices/area

$PROGDIR/ConvertImageSeries $MRIMASK_INDIR/slices ${MRIMASK_INNAME}_slice%03d.nii.gz $MRIMASK_INDIR/${MRIMASK_INNAME}.nii.gz 

# make sure the file is empty before the run
rm -rf $MRIMASK_INDIR/slices/area/$logfile

# make a directory to record the data
nslice=`ls $MRIMASK_INDIR/slices | grep "\.nii\.gz" | wc -l`
for ((i=0; i<$nslice; i++ ))
do 
  ipad=`printf %03d $i`
  echo $ipad `$C3DDIR/c3d $MRIMASK_INDIR/slices/${MRIMASK_INNAME}_slice${ipad}.nii.gz -voxel-sum` \
   >> $MRIMASK_INDIR/slices/area/$logfile
done

