#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

TXPATH=$1 
VECTORPATH=$TXPATH/vector
TXSMOOTHPATH=$TXPATH/../tx_smooth
VECTORSMOOTHPATH=$TXSMOOTHPATH/vector

# Make sure the directories exist
mkdir -p $VECTORPATH
mkdir -p $TXSMOOTHPATH
mkdir -p $VECTORSMOOTHPATH

# Make sure directories are clean
rm -f $VECTORPATH/*.*
rm -f $TXSMOOTHPATH/*.*
rm -f $VECTORSMOOTHPATH/*.*

# Set smoothing parameters
sigma="2.0"

# Get the mean of the image center and then set the fixed parameter 
sum_centerx=0
sum_centery=0
for transfile in `ls -1 $TXPATH | grep ".txt"`
do
  centerx=`grep "^FixedParameters" $TXPATH/$transfile | awk '{print $2}'`
  centery=`grep "^FixedParameters" $TXPATH/$transfile | awk '{print $3}'`
  sum_centerx=`echo $sum_centerx + $centerx | bc -l`
  sum_centery=`echo $sum_centery + $centery | bc -l`
done
nslice=`ls -1 $TXPATH | grep ".txt" | wc -l`

mean_centerx=`echo "scale=6;$sum_centerx / $nslice" | bc -l`
mean_centery=`echo "scale=6;$sum_centery / $nslice" | bc -l`


# Define a function to calculate the rotation angle and translation of an ANTS affine.txt file
function vector()
{
  antsfile=$1
  vectorfile=$2
	# $1 is input file name and $2 is output file name
  # use cos and sin to calculate the angle of the rotation
	local cos=`grep "^Parameters" $antsfile | awk '{print $2}'`
	local sin=`grep "^Parameters" $antsfile | awk '{print $3}'`
	# just in case of the scientific notation 
	local sin=`echo $sin | sed "s/[Ee]/\*10\^/g"`
	local cos=`echo $cos | sed "s/[Ee]/\*10\^/g"`
  local angle=`echo "scale=6; a((${sin})/(${cos}));" | bc -l`
	
	local transx=`grep "^Parameters" $antsfile | awk '{print $6}'`
	local transy=`grep "^Parameters" $antsfile | awk '{print $7}'`
	local centerx=`grep "^FixedParameters" $antsfile | awk '{print $2}'`
	local centery=`grep "^FixedParameters" $antsfile | awk '{print $3}'`
  # just in case of the scientific notation 
	local transx=`echo $transx | sed "s/[Ee]/\*10\^/g"`
	local transy=`echo $transy | sed "s/[Ee]/\*10\^/g"`
	local centerx=`echo $centerx | sed "s/[Ee]/\*10\^/g"`
	local centery=`echo $centery | sed "s/[Ee]/\*10\^/g"`


# calculate the translation when rotation is around mean_center
  local transx_center=`echo "(1-$cos)*($centerx - ($mean_centerx)) - ($sin*($centery - ($mean_centery))) + $transx" | bc -l`
  local transy_center=`echo "(1-$cos)*($centery - ($mean_centery)) + ($sin*($centerx -($mean_centerx))) + $transy" | bc -l`

  echo -e "${angle}\n${transx_center}\n${transy_center}" > $vectorfile
}

# Loop through all transformations (rigid-body from histo slice to MRI slice)

for transfile in `ls -1 $TXPATH | grep ".txt"`
do
 vector $TXPATH/$transfile $VECTORPATH/$transfile
done

# apply smoothing to the data
$PROGDIR/smooth_transforms -s 4.0 $VECTORPATH $VECTORSMOOTHPATH `ls -1 $VECTORPATH | grep "Affine.txt"`


function PrintANTSAffine {
  vectorfile=$1
  antsfile=$2
  local angle=`cat $vectorfile | head -n 1 | tail -n 1`
  local transx=`cat $vectorfile | head -n 2 | tail -n 1`
  local transy=`cat $vectorfile | head -n 3 | tail -n 1`

	local angle=`echo $angle | sed "s/[Ee]/\*10\^/g"`

  local cosangle=`echo "scale=6; c(${angle});" | bc -l`
  local sinangle=`echo "scale=6; s(${angle});" | bc -l`
  local negsinangle=`echo "scale=6; -s(${angle});" | bc -l`


 
  echo "#Insight Transform File V1.0" >> $antsfile
  echo "#Transform 0" >> $antsfile
  echo "Transform: MatrixOffsetTransformBase_double_2_2" >> $antsfile
  echo "Parameters: $cosangle $sinangle $negsinangle $cosangle $transx $transy" >> $antsfile
  echo "FixedParameters: $mean_centerx $mean_centery"  >> $antsfile
}

for transfile in `ls -1 $VECTORSMOOTHPATH | grep ".txt"` 
do
  
	PrintANTSAffine $VECTORSMOOTHPATH/$transfile $TXSMOOTHPATH/$transfile
	                
done

