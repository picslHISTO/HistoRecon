#!/bin/bash
# ==============================
# get spacing of the image
# ==============================

source /home/liuyang/mouse10/scripts/common.sh


# usage 
# the orientation accept a permutation of RAI (eg. RIA, IRA), which corresponds to the x, y and z
# direction of your current 2D image.
# the spacing should be three numbers all in mm and still corresponds to your original x,y,z
# you can checkout the data/input/volume directory to see whether your input is correct

mkdir -p $PARMDIR
# if the spacing is specified from the command line
if [[ -n $1 ]] ; then
  orient=$1
  spacingx=$2
  spacingy=$3
  spacingz=$4
  flip=''
  flip_option=''

  # make the judgement on the flipping depending on the sign of spacing

  if [ ${spacingx:0:1} == '-' ]
  then 
    flip="${flip}x"
    spacingx=${spacingx#\-}
  fi

  if [ ${spacingy:0:1} == '-' ]
  then 
    flip="${flip}y"
    spacingy=${spacingy#\-}
  fi

  if [ ${spacingz:0:1} == '-' ]
  then 
    flip="${flip}z"
    spacingz=${spacingz#\-}
  fi

  rm $PARMDIR/spacing.txt
  echo $orient   >> $PARMDIR/spacing.txt
  echo $flip     >> $PARMDIR/spacing.txt
  echo $spacingx >> $PARMDIR/spacing.txt
  echo $spacingy >> $PARMDIR/spacing.txt
  echo $spacingz >> $PARMDIR/spacing.txt
fi

orient=`cat $PARMDIR/spacing.txt | head -n 1 | tail -n 1`
flip=`cat $PARMDIR/spacing.txt | head -n 2 | tail -n 1`
spacingx=`cat $PARMDIR/spacing.txt | head -n 3 | tail -n 1`
spacingy=`cat $PARMDIR/spacing.txt | head -n 4 | tail -n 1`
spacingz=`cat $PARMDIR/spacing.txt | head -n 5 | tail -n 1`

if [ -n "$flip" ] 
then
	flip_option="-flip $flip"
else
	flip_option=''
fi 

INPUTPATH=$GRAYDIR
OUTPUTPATH=$DATADIR/input/tmp
VOLUMEPATH=$DATADIR/input/volume

mkdir -p $OUTPUTPATH
mkdir -p $VOLUMEPATH

# change the spacing of the 2D image
echo "Changing the spacing of the 2D image"
for img in `ls $GRAYDIR`
do
  $C3DDIR/c2d $GRAYDIR/$img -spacing ${spacingx}x${spacingy}mm -o $GRAYDIR/$img
done

num=`ls -1 $INPUTPATH | wc -l`
REFIMG=`ls -1 $INPUTPATH | head -n $((num/2)) | tail -n 1`
for img in `ls -1 $INPUTPATH`
do 
$ANTSDIR/WarpImageMultiTransform 2 "$INPUTPATH/$img" \
																		 "$OUTPUTPATH/$img" \
																		 --Id \
																 -R  "$INPUTPATH/$REFIMG"
																 
done

$PROGDIR/imageSeriesToVolume -o "$VOLUMEPATH/volume.nii.gz" \
                             -sx $spacingx -sy $spacingy -sz $spacingz \
                             -i `ls -1 $OUTPUTPATH/*.nii.gz`

# flip option should go before the permute axis
$C3DDIR/c3d $VOLUMEPATH/volume.nii.gz \
$flip_option \
-pa $orient \
-orient RAI -origin 0x0x0mm \
-o $VOLUMEPATH/volume.nii.gz


# Record the information for the reoriented data
rm $PARMDIR/spacing_reoriented.txt
$C3DDIR/c3d $VOLUMEPATH/volume.nii.gz -info-full | grep "pixdim\[[1-3]\]"  | \
sed -r "s/pixdim\[[1-3]\] = //g" | sed "s/ //g" \
>> $PARMDIR/spacing_reoriented.txt

# For the inverse transform
orient_inverse=''
if [[ ${orient:0:1} == 'x' ]]; then
  orient_inverse=${orient_inverse}x
elif [[ ${orient:1:1} == 'x' ]]; then
  orient_inverse=${orient_inverse}y
elif [[ ${orient:2:1} == 'x' ]]; then
  orient_inverse=${orient_inverse}z
fi

if [[ ${orient:0:1} == 'y' ]]; then
  orient_inverse=${orient_inverse}x
elif [[ ${orient:1:1} == 'y' ]]; then
  orient_inverse=${orient_inverse}y
elif [[ ${orient:2:1} == 'y' ]]; then
  orient_inverse=${orient_inverse}z
fi

if [[ ${orient:0:1} == 'z' ]]; then
  orient_inverse=${orient_inverse}x
elif [[ ${orient:1:1} == 'z' ]]; then
  orient_inverse=${orient_inverse}y
elif [[ ${orient:2:1} == 'z' ]]; then
  orient_inverse=${orient_inverse}z
fi

echo "reorient the mri images"

MRI_INDIR="$DATADIR/input/mri"
MRI_INNAME="canon_T1_r_halfsize_origin000_masked"
MRILABEL_INDIR="$DATADIR/input/mri"
MRILABEL_INNAME="waxholm_label_halfsize_origin000"

MRI_OUTDIR="$DATADIR/input/mri_oriented"
MRI_OUTNAME="mri"
MRILABEL_OUTDIR="$DATADIR/input/mri_oriented/label"
MRILABEL_OUTNAME="mri_label"
mkdir -p $MRI_OUTDIR
mkdir -p $MRILABEL_OUTDIR

cp $MRI_INDIR/${MRI_INNAME}.nii.gz $MRI_OUTDIR/${MRI_OUTNAME}_oriented.nii.gz
cp $MRILABEL_INDIR/${MRILABEL_INNAME}.nii.gz $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}_oriented.nii.gz

# If you use the inverse you should apply reorient first then flip

$C3DDIR/c3d $MRI_OUTDIR/${MRI_OUTNAME}_oriented.nii.gz \
-pa $orient_inverse \
$flip_option \
-orient RAI -origin 0x0x0mm \
-o $MRI_OUTDIR/${MRI_OUTNAME}.nii.gz 


$C3DDIR/c3d $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}_oriented.nii.gz \
-pa $orient_inverse \
$flip_option \
-orient RAI -origin 0x0x0mm \
-o $MRILABEL_OUTDIR/${MRILABEL_OUTNAME}.nii.gz 

