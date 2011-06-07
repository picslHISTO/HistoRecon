#!/bin/bash
source ../common.sh

# Make sure the directories exist
mkdir -p $H2MDIR/tx/vector

mkdir -p $SMOOTHDIR
mkdir -p $SMOOTHDIR/tx_smooth
mkdir -p $SMOOTHDIR/tx_smooth/vector
mkdir -p $SMOOTHDIR/volume

mkdir -p $SMOOTHDIR/reslice/orig
mkdir -p $SMOOTHDIR/reslice/mask
mkdir -p $SMOOTHDIR/reslice/masked

# mkdir -p $SMOOTHDIR/reslice/orig/small
# mkdir -p $SMOOTHDIR/reslice/mask/small
# mkdir -p $SMOOTHDIR/reslice/masked/small

# Set smoothing parameters
sigma="0.1"

# Loop through all transformations (rigid-body from histo slice to MRI slice)
for transfile in `ls -1 $H2MDIR/tx | grep ".mat" | sed -e 's/\.mat//'`
do
  # get first two lines of the 4x4 affine matrix
  line1=`cat $H2MDIR/tx/${transfile}.mat | head -n 1 | tail -n 1`
  line2=`cat $H2MDIR/tx/${transfile}.mat | head -n 2 | tail -n 1`
  
  # a1 = cos(angle), b1 = -sin(angle), c1 = 0, d1 = translationx
  # a2 = sin(angle), b2 =  cos(angle), c2 = 0, d2 = translationy
  read -r a1 b1 c1 d1 <<< $line1
  read -r a2 b2 c2 d2 <<< $line2
#  echo "a=$a, b=$b, c=$c, d=$d"

  # compute angle using arctan(sin(angle)/cos(angle))
  angle=`echo "scale=10; a(${a2}/${a1});" | bc -l`
  transx=$d1
  transy=$d2
#  angle=`python -c "print atan2($b,$a)"`

  echo -e "${angle}\n${transx}\n${transy}" > "$H2MDIR/tx/vector/${transfile}_vector.txt"
done


# Apply smoothing to the data
$PROGDIR/smooth_transforms -s ${sigma} $H2MDIR/tx/vector $SMOOTHDIR/tx_smooth/vector `ls -1 $H2MDIR/tx/vector | grep "vector.txt"`

for transfile in `ls -1 $SMOOTHDIR/tx_smooth/vector | grep "vector.txt" | sed -e 's/_vector\.txt//'`
do
  angle=`cat $SMOOTHDIR/tx_smooth/vector/${transfile}_vector.txt | head -n 1 | tail -n 1`
  transx=`cat $SMOOTHDIR/tx_smooth/vector/${transfile}_vector.txt | head -n 2 | tail -n 1`
  transy=`cat $SMOOTHDIR/tx_smooth/vector/${transfile}_vector.txt | head -n 3 | tail -n 1`
#  echo "angle=$angle, transx=$transx, transy=$transy"

  cosangle=`echo "scale=6; c(${angle});" | bc -l`
  sinangle=`echo "scale=6; s(${angle});" | bc -l`
  negsinangle=`echo "scale=6; -s(${angle});" | bc -l`
  
  echo -e "${cosangle} ${negsinangle} 0 ${transx}" > "$SMOOTHDIR/tx_smooth/${transfile}_smooth.mat"
  echo -e "${sinangle} ${cosangle} 0 ${transy}"   >> "$SMOOTHDIR/tx_smooth/${transfile}_smooth.mat"
  echo -e "0 0 1 0"                               >> "$SMOOTHDIR/tx_smooth/${transfile}_smooth.mat"
  echo -e "0 0 0 1"                               >> "$SMOOTHDIR/tx_smooth/${transfile}_smooth.mat"
done


histoslices=`ls -1 $LINEARDIR/reslice/orig | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//"`

k=0
for i in $histoslices
do
  qsub -N "smooth_${k}" -o $OUTPUTDIR -e $ERRORDIR smooth_h2m_tx.qsub.sh $i $k
  let k=k+1
done

qblock
spacex=0.0507
spacey=0.0507
spacez=0.200

$PROGDIR/imageSeriesToVolume -o "$SMOOTHDIR/volume/rigid_histo_to_mri_smooth.nii.gz" \
                             -sx $spacex -sy $spacey -sz $spacez \
                             -i `ls -1 $SMOOTHDIR/reslice/orig/*.nii.gz`

$PROGDIR/imageSeriesToVolume -o "$SMOOTHDIR/volume/rigid_histo_to_mri_mask_smooth.nii.gz" \
                             -sx $spacex -sy $spacey -sz $spacez \
                             -i `ls -1 $SMOOTHDIR/reslice/mask/*.nii.gz`

$PROGDIR/imageSeriesToVolume -o "$SMOOTHDIR/volume/rigid_histo_to_mri_masked_smooth.nii.gz" \
                             -sx $spacex -sy $spacey -sz $spacez \
                             -i `ls -1 $SMOOTHDIR/reslice/masked/*.nii.gz`
