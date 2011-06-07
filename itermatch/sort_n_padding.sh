source ../common.sh


HISTOMASK_SLICE_INDIR="$STACKINGDIR/reslice/mask"
HISTOMASK_SLICE_INNAME="reslice_histo_mask_slice"
MRIMASK_SLICE_INDIR="$DATADIR/input/mri_oriented/mask/slices"
MRIMASK_SLICE_INNAME="mri_mask_slice"

HISTO_log_dir="$HISTOMASK_SLICE_INDIR/area"
MRI_log_dir="$MRIMASK_SLICE_INDIR/area"
logfile="area.txt"

HISTOMASK_OUTDIR="$HISTO_log_dir"
MRIMASK_OUTDIR="$MRI_log_dir"
mkdir -p $HISTOMASK_OUTDIR/volume
mkdir -p $MRIMASK_OUTDIR/volume

# for histology
array=(`cat $HISTO_log_dir/$logfile | sort -nk4 | tail -n 1`)
nslice=`ls $HISTOMASK_SLICE_INDIR | grep "\.nii\.gz" | wc -l`
mkdir -p $HISTOMASK_OUTDIR/slices

# cp the original slices over
for ((i=0;i<${array[0]};i++))
do
  ipad=`printf %05d $i`

  cp $HISTOMASK_SLICE_INDIR/${HISTOMASK_SLICE_INNAME}${ipad}.nii.gz $HISTOMASK_OUTDIR/slices/histomask${ipad}.nii.gz
done

# create some blank slices
for ((i=${array[0]};i<$nslice;i++))
do
  ipad=`printf %05d $i`
  $C3DDIR/c2d $HISTOMASK_SLICE_INDIR/${HISTOMASK_SLICE_INNAME}${ipad}.nii.gz -scale 0 -o $HISTOMASK_OUTDIR/slices/histomask${ipad}.nii.gz
done

$PROGDIR/imageSeriesToVolume -o "$HISTOMASK_OUTDIR/volume/histo_mask.nii.gz" \
                             -sx $HSPACEX -sy $HSPACEY -sz $HSPACEZ \
                             -i `ls -1 $HISTOMASK_OUTDIR/slices/*.nii.gz`


# for mri 
# get the spacing for the original mri
array=(`cat $MRI_log_dir/$logfile | sort -nk4 | tail -n 1`)
nslice=`ls $MRIMASK_SLICE_INDIR | grep "\.nii\.gz" | wc -l`
mkdir -p $MRIMASK_OUTDIR/slices

for ((i=0;i<${array[0]};i++))
do
  ipad=`printf %03d $i`
  cp $MRIMASK_SLICE_INDIR/${MRIMASK_SLICE_INNAME}${ipad}.nii.gz $MRIMASK_OUTDIR/slices/mrimask${ipad}.nii.gz
done

# create some blank slices
for ((i=${array[0]};i<$nslice;i++))
do
  ipad=`printf %03d $i`
  $C3DDIR/c2d $MRIMASK_SLICE_INDIR/${MRIMASK_SLICE_INNAME}${ipad}.nii.gz -scale 0 -o $MRIMASK_OUTDIR/slices/mrimask${ipad}.nii.gz
done

$PROGDIR/imageSeriesToVolume -o "$MRIMASK_OUTDIR/volume/mri_mask.nii.gz" \
                             -sz 0.043 -sx 0.043 -sy 0.043\
                             -i `ls -1 $MRIMASK_OUTDIR/slices/*.nii.gz`



