#!/bin/bash
# ================================
# Rigid registration script (2)
# ================================
# Computes a volume based on registration of neighboring slices
# Make sure you run reg_m23.sh before running this script!

source ../common.sh

# make sure directories exist
mkdir -p $STACKINGDIR/paths
mkdir -p $STACKINGDIR/accum

mkdir -p $STACKINGDIR/reslice
mkdir -p $STACKINGDIR/reslice/mask

mkdir -p $STACKINGDIR/volume
mkdir -p $STACKINGDIR/volume/mask

# make sure directories are clean
rm -f $STACKINGDIR/paths/*.*
rm -f $STACKINGDIR/accum/*.*

rm -f $STACKINGDIR/reslice/*.*
rm -f $STACKINGDIR/reslice/mask/*.*

rm -f $STACKINGDIR/volume/*.*
rm -f $STACKINGDIR/volume/mask/*.*

# Get the list of the slice numbers
slices=(`ls -1 $GRAYDIR | grep "nii.gz" | sed -e "s/\.nii\.gz//"`)
echo -e "Slices: ${slices[@]}\n"
# | wc --words | sed -e "s/ //g"
nslices=${#slices[*]}
echo -e "Number of slices = $nslices\n"

# The user can specify a slice used as the reference.
# If not, we will select the half-way slice as the reference
if [ ! $REFERENCE_SLICE ]
then
  echo -e "\n**No reference slice supplied!**\n"
  iref=`expr $nslices / 2`
  REFERENCE_SLICE=${slices[${iref}]}
fi
echo -e "Using $REFERENCE_SLICE as the reference\n"

####################################################
#  Shortest Path
####################################################

# The location of the path file
pathfile=$STACKINGDIR/paths/shortestpath.txt

# Define function for computing the paths from each slice to the reference slice
function ShortestPath()
{
  # List all the available forward transforms by looking in the match directory
  matchlist=$TMPDIR/matchlist.txt
  ls -1 "${STACKINGDIR}/metric" | grep "metric_ncor.*.txt" > $matchlist

  # Build the adjacency list from the alignment computations
  adjfile=$STACKINGDIR/paths/adjacency.txt
  for i in ${slices[*]}
  do
    local hops=0
    # get match between slice i and its 5 neighbours
    for j in `grep "metric_ncor_linear_${i}" < $matchlist`
    do
      # final metric value is 2nd line in file
      # (1st line is initial metric value)
      match=`cat $STACKINGDIR/metric/$j | tail -n 1`
      match=`python -c "print 1 - $match"`
      if [ ! $match ]
      then
        match="0.00"
      fi
      echo `echo $j | sed -e "s/metric_ncor_linear_//" -e "s/_to_/ /" -e "s/\..*//"` $match $hops
      let hops=hops+1
    done
  done > $adjfile
  echo "Placed adjacency list into $adjfile"

  # Compute the file telling us the predecessor for each individual
  # regpath computes the shortest path (??) to the reference slices
  $PROGDIR/regpath $adjfile $REFERENCE_SLICE 1.0 > $pathfile
  echo "Wrote predecessor info into $pathfile"
}

# Call the shortest path computation
ShortestPath

####################################################
#  Accumulate Path
####################################################

# Now we can compute cumulative transforms
echo "Computing cumulative transforms"

# Clear the accumulator directory
rm -rf $STACKINGDIR/accum/*.txt

# Create an identity transform for the reference slice
if [[ ${STACKING_RECON_PROG} == "ANTS" ]]; then
	# using ANTS
  ls $STACKINGDIR/tx/* | grep ${REFERENCE_SLICE} | head -n 1 | tail -n 1 | xargs cat | sed -r "s/^Parameters:.*/Parameters:\ 1 \ 0 \ 0 \ 1 \ 0 \ 0/g" \
    > "$STACKINGDIR/accum/linear_${REFERENCE_SLICE}_to_${REFERENCE_SLICE}_Affine.txt"
else
	# using FSL
	echo -e "1 0 0 0\n0 1 0 0\n0 0 1 0\n0 0 0 1\n" \
    	 > "$STACKINGDIR/accum/linear_${REFERENCE_SLICE}_to_${REFERENCE_SLICE}.mat"
fi

# Now, define a recursive function that for each slice finds its predecessor
Accumulate_ANTS()
{
  local moving=$1
  local target=`grep "^$1" < $pathfile | sed -e "s/ /\n/g" | head -n 2 | tail -n 1`
  
  local movingtx="linear_${moving}_to_${REFERENCE_SLICE}_Affine"
  local targettx="linear_${target}_to_${REFERENCE_SLICE}_Affine"
  local inttx="linear_${moving}_to_${target}_Affine"

  # intinvtx is the inverse transform of inttx
  local intinvtx="linear_${target}_to_${moving}_Affine"

  if [ ! -f "$STACKINGDIR/accum/${movingtx}.txt" ]; then
    if [ ! -f "$STACKINGDIR/accum/${targettx}.txt" ]; then
      # Call up the chain
      Accumulate_ANTS $target
    fi

    echo "Combining $inttx and $targettx to form $movingtx"
	
    # Use the inverse transform if the forward transform does not exist
    if [ ! -f "$STACKINGDIR/tx/${inttx}.txt" ]; then
    
      # linear transform version
      $ANTSDIR/ComposeMultiTransform 2 $STACKINGDIR/accum/${movingtx}.txt \
      -R  $STACKINGDIR/accum/linear_${REFERENCE_SLICE}_to_${REFERENCE_SLICE}_Affine.txt \
      -i $STACKINGDIR/tx/${intinvtx}.txt $STACKINGDIR/accum/${targettx}.txt
    
    else
      $ANTSDIR/ComposeMultiTransform 2 $STACKINGDIR/accum/${movingtx}.txt $STACKINGDIR/tx/${inttx}.txt $STACKINGDIR/accum/${targettx}.txt
        
    fi
  fi
}



Accumulate_FSL()
{
	local moving=$1
	local target=`grep "^$1" < $pathfile | sed -e "s/ /\n/g" | head -n 2 | tail -n 1`
  
	local movingtx="linear_${moving}_to_${REFERENCE_SLICE}"
	local targettx="linear_${target}_to_${REFERENCE_SLICE}"
	local inttx="linear_${moving}_to_${target}"

	if [ ! -f "$STACKINGDIR/accum/${movingtx}.mat" ]; then
		if [ ! -f "$STACKINGDIR/accum/${targettx}.mat" ]; then
			# Call up the chain
			Accumulate_FSL $target
		fi

		echo "Combining $inttx and $targettx to form $movingtx"
		    
		$FSLDIR/convert_xfm -omat   "$STACKINGDIR/accum/${movingtx}.mat" \
							-concat "$STACKINGDIR/accum/${targettx}.mat" \
							"$STACKINGDIR/tx/${inttx}.mat"   
  fi
}

# Call this function for every linear transform file there is
for i in ${slices[*]}
do
	echo "  Accumulate $i"
	
	# Accumulate the linear transforms up to this point
	if [[ ${STACKING_RECON_PROG} == "ANTS" ]]; then
		Accumulate_ANTS $i 
  elif [[ ${STACKING_RECON_PROG} == "FSL" ]]; then
		Accumulate_FSL $i
	fi

done

####################################################
#  Reslice the image
####################################################

# Now, reslice all the images using the concatenated transform files. 
# echo "Reconstructing the slices" 
# Attention: the mask names may vary for the new data if the user provides the masks in advance
nslices=`ls -1 $GRAYDIR | grep "\.nii\.gz" | wc -l`
masks=(`ls -1 $MASKDIR | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//"`)

for ((i=0; i < nslices; i++)) 
do
	ipad=`printf %05d $i`
	mov=${slices[${i}]}
	mask=${masks[${i}]}

  exe "reslice.$i" 1 reslice.qsub.sh \
  $mov $REFERENCE_SLICE $mask $ipad
done

qblock "reslice"

# Rebuild the volume
echo "Building a 3D volume [$STACKINGDIR/volume/]"
echo $STACKINGDIR


if [ -n "$HISTO_FLIP" ] 
then
	flip_option="-flip $HISTO_FLIP"
else
	flip_option=''
fi

# question: change to Nick's program ConvertImageSeriess
$PROGDIR/imageSeriesToVolume -o "$STACKINGDIR/volume/reslice_histo.nii.gz" \
                             -sx $HSPACEX -sy $HSPACEY -sz $HSPACEZ \
                             -i `ls -1 $STACKINGDIR/reslice/*.nii.gz`
$PROGDIR/imageSeriesToVolume -o "$STACKINGDIR/volume/mask/reslice_histo_mask.nii.gz" \
                             -sx $HSPACEX -sy $HSPACEY -sz $HSPACEZ \
                             -i `ls -1 $STACKINGDIR/reslice/mask/*.nii.gz`

$C3DDIR/c3d $STACKINGDIR/volume/reslice_histo.nii.gz \
$flip_option \
-pa $HISTO_ORIENT \
-orient RAI -origin 0x0x0mm \
-o $STACKINGDIR/volume/reslice_histo_oriented.nii.gz \

$C3DDIR/c3d $STACKINGDIR/volume/mask/reslice_histo_mask.nii.gz \
$flip_option \
-pa $HISTO_ORIENT \
-orient RAI -origin 0x0x0mm \
-o $STACKINGDIR/volume/mask/reslice_histo_mask_oriented.nii.gz 

# codes for ants deformable (not used here)
		# elif [[ ${STACKING_RECON_PROG} == "ANTS" ]]; then
    # deformable transform version
	  #      echo "-i $STACKINGDIR/tx/${intinvtx}_Affine.txt $STACKINGDIR/tx/${intinvtx}_InverseWarp.nii.gz" \
    #	         `cat $STACKINGDIR/accum/${targettx}.txt` \
		#	     > $STACKINGDIR/accum/${movingtx}.txt
# fi



		# elif [[ ${STACKING_RECON_PROG} == "ANTS_DEFORMABLE" ]]; then
			# deformable transform version
	   #    echo "$STACKINGDIR/tx/${inttx}_Warp.txt $STACKINGDIR/tx/${inttx}_Affine.txt" \
    #	        `cat $STACKINGDIR/accum/${targettx}.txt` \
	  # 		     > $STACKINGDIR/accum/${movingtx}.txt
	  # 	fi
