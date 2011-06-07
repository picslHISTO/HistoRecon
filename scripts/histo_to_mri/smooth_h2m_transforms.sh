#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y
source /home/liuyang/mouse9/scripts/common.sh


TXPATH=$H2MDIR/tx
VECTORPATH=$TXPATH/vector
TXSMOOTHPATH=$H2MDIR/tx_smooth
VECTORSMOOTHPATH=$TXSMOOTHPATH/vector

MRIPATH=$H2MDIR/mri
HISTOPATH=$H2MDIR/histo
HISTOMASKPATH=$H2MDIR/histo/mask
TRGPATH=$H2MDIR/reslice
TRGMASKPATH=$H2MDIR/reslice/mask
VOLUMEPATH=$H2MDIR/volume
VOLUMEMASKPATH=$H2MDIR/volume/mask



# Make sure the directories exist
mkdir -p $VECTORPATH
mkdir -p $TXSMOOTHPATH
mkdir -p $VECTORSMOOTHPATH
mkdir -p $TRGPATH
mkdir -p $TRGMASKPATH
mkdir -p $VOLUMEPATH
mkdir -p $VOLUMEMASKPATH

# Make sure directories are clean
rm -f $VECTORPATH/*.*
rm -f $TXSMOOTHPATH/*.*
rm -f $VECTORSMOOTHPATH/*.*
rm -f $TRGPATH/*.*
rm -f $TRGMASKPATH/*.*

# Set smoothing parameters
sigma="1"



for transfile in `ls -1 $TXPATH | grep ".mat" | sed -e 's/\.mat//'`
do



  # get first two lines of the 4x4 affine matrix
  line1=`cat $TXPATH/${transfile}.mat | head -n 1 | tail -n 1`
  line2=`cat $TXPATH/${transfile}.mat | head -n 2 | tail -n 1`
  
  # a1 = cos(angle), b1 = -sin(angle), c1 = 0, d1 = translationx
  # a2 = sin(angle), b2 =  cos(angle), c2 = 0, d2 = translationy
  read -r a1 b1 c1 d1 <<< $line1
  read -r a2 b2 c2 d2 <<< $line2
#  echo "a=$a, b=$b, c=$c, d=$d"

  # compute angle using arctan(sin(angle)/cos(angle))
  a1=`echo $a1 | sed "s/[Ee]/\*10\^/g"`
  a2=`echo $a2 | sed "s/[Ee]/\*10\^/g"`
  #echo "scale=10; a(${a2}/${a1});"
  angle=`echo "scale=10; a(${a2}/${a1});" | bc -l`
  transx=$d1
  transy=$d2
#  angle=`python -c "print atan2($b,$a)"`

  echo -e "${angle}\n${transx}\n${transy}" > "$VECTORPATH/${transfile}_vector.txt"
done



# apply smoothing to the data
$PROGDIR/smooth_transforms -s $sigma $VECTORPATH $VECTORSMOOTHPATH `ls -1 $VECTORPATH | grep "vector.txt"`




for transfile in `ls -1 $VECTORSMOOTHPATH | grep "vector.txt"| sed -e 's/_vector\.txt//'` 
do


  angle=`cat $VECTORSMOOTHPATH/${transfile}_vector.txt | head -n 1 | tail -n 1`
  transx=`cat $VECTORSMOOTHPATH/${transfile}_vector.txt | head -n 2 | tail -n 1`
  transy=`cat $VECTORSMOOTHPATH/${transfile}_vector.txt | head -n 3 | tail -n 1`
  # echo "angle=$angle, transx=$transx, transy=$transy"

  cosangle=`echo "scale=6; c(${angle});" | bc -l`
  sinangle=`echo "scale=6; s(${angle});" | bc -l`
  negsinangle=`echo "scale=6; -s(${angle});" | bc -l`
  
	echo -e "${cosangle} ${negsinangle} 0 ${transx}" > "$TXSMOOTHPATH/${transfile}_smooth.mat"
  echo -e "${sinangle} ${cosangle} 0 ${transy}"   >> "$TXSMOOTHPATH/${transfile}_smooth.mat"
  echo -e "0 0 1 0"                               >> "$TXSMOOTHPATH/${transfile}_smooth.mat"
  echo -e "0 0 0 1"                               >> "$TXSMOOTHPATH/${transfile}_smooth.mat"
done




nslices=`ls -1 $MRIPATH | grep "\.nii\.gz" | wc -l`
for ((i=1;i<=nslices;i++))
do
	mrislice=`ls -1 $MRIPATH | grep "\.nii\.gz" | head -n $i | tail -n 1 | sed -e "s/\.nii\.gz//"`
	histoslice=`ls -1 $HISTOPATH | grep "\.nii\.gz" | head -n $i | tail -n 1 | sed -e "s/\.nii\.gz//"`
	histomaskslice=`ls -1 $HISTOMASKPATH | grep "\.nii\.gz" | head -n $i | tail -n 1 | sed -e "s/\.nii\.gz//"`
	tx_smooth=`ls -1 $TXSMOOTHPATH | grep ".mat" | head -n $i | tail -n 1 | sed -e "s/\.mat//"`
	pwd

   qsub -N "reslice_smooth${i}" -o $OUTPUTDIR -e $ERRORDIR \
	$SCRIPTDIR/histo_to_mri/smooth_h2m_transforms.qsub.sh \
	$mrislice $histoslice $histomaskslice $tx_smooth
# bash 	$SCRIPTDIR/histo_to_mri/smooth_h2m_transforms.qsub.sh \
	# $mrislice $histoslice $histomaskslice $tx_smooth

done

qblock

# Get the information for spacing
orient=`cat $PARMDIR/spacing.txt | head -n 1 | tail -n 1`
slice_direction=${orient:2:1}
orient_new=`echo xyz | sed -e "s/$slice_direction//g"`"${slice_direction}" 

$PROGDIR/imageSeriesToVolume -o "$H2MDIR/volume/rigid_histo_to_mri_smooth.nii.gz" \
                             -i `ls -1 $TRGPATH/*.nii.gz`
$PROGDIR/imageSeriesToVolume -o "$H2MDIR/volume/mask/rigid_histo_to_mri_smooth_mask.nii.gz" \
                             -i `ls -1 $TRGMASKPATH/*.nii.gz`


spacingx_r=`cat $PARMDIR/spacing_reoriented.txt | head -n 1 | tail -n 1`
spacingy_r=`cat $PARMDIR/spacing_reoriented.txt | head -n 2 | tail -n 1`
spacingz_r=`cat $PARMDIR/spacing_reoriented.txt | head -n 3 | tail -n 1`



$C3DDIR/c3d $H2MDIR/volume/rigid_histo_to_mri_smooth.nii.gz \
-pa $orient_new \
-orient RAI -origin 0x0x0mm \
-spacing ${spacingx_r}x${spacingy_r}x${spacingz_r}mm \
-o $H2MDIR/volume/rigid_histo_to_mri_smooth_respacing.nii.gz

$C3DDIR/c3d $H2MDIR/volume/mask/rigid_histo_to_mri_smooth_mask.nii.gz \
-pa $orient_new \
-orient RAI -origin 0x0x0mm \
-spacing ${spacingx_r}x${spacingy_r}x${spacingz_r}mm \
-o $H2MDIR/volume/mask/rigid_histo_to_mri_smooth_mask_respacing.nii.gz

