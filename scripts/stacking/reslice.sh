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
if [ ! $REF_SLICE ]
then
  echo -e "\n**No reference slice supplied!**\n"
  iref=`expr $nslices / 2`
  REF_SLICE=${slices[${iref}]}
fi
echo -e "Using $REF_SLICE as the reference\n"

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
  for moving in ${slices[*]}
  do
    local hops=0
    # get match between slice i and its 5 neighbours
    for transfile in `grep "metric_ncor_.*_mov_${moving}" < $matchlist`
    do
      # final metric value is 2nd line in file
      # (1st line is initial metric value)
      match=`cat $STACKINGDIR/metric/$transfile | tail -n 1`
      match=`python -c "print 1 - $match"`
      if [ ! $match ]
      then
        match="0.00"
      fi
      fixed=`echo $transfile | sed -e "s/.*_fix_//" -e "s/_mov_.*//"`
      echo $moving $fixed $match $hops
      let hops=hops+1
    done
  done > $adjfile
  echo "Placed adjacency list into $adjfile"

  # Compute the file telling us the predecessor for each individual
  # regpath computes the shortest path (??) to the reference slices
  python $PROGDIR/regpath.py $adjfile $REF_SLICE > $pathfile
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
  ls $STACKINGDIR/tx/* | grep ${REF_SLICE} | head -n 1 | tail -n 1 | xargs cat | sed -r "s/^Parameters:.*/Parameters:\ 1 \ 0 \ 0 \ 1 \ 0 \ 0/g" \
    > "$STACKINGDIR/accum/linear_fix_${REF_SLICE}_mov_${REF_SLICE}_Affine.txt"
else
	# using FSL
	echo -e "1 0 0 0\n0 1 0 0\n0 0 1 0\n0 0 0 1\n" \
    	 > "$STACKINGDIR/accum/linear_fix_${REF_SLICE}_mov_${REF_SLICE}.mat"
fi

# Now, define a recursive function that for each slice finds its predecessor
Accumulate_ANTS()
{
  local new=$1
  local pre=`grep "^$1" < $pathfile | sed -e "s/ /\n/g" | head -n 2 | tail -n 1`
  


  local newtx="linear_fix_${REF_SLICE}_mov_${new}_Affine"
  local pretx="linear_fix_${REF_SLICE}_mov_${pre}_Affine"
  local inttx="linear_fix_${pre}_mov_${new}_Affine"

  # intinvtx is the inverse transform of inttx
  local intinvtx="linear_fix_${new}_mov_${pre}_Affine"

  if [ ! -f "$STACKINGDIR/accum/${newtx}.txt" ]; then
    if [ ! -f "$STACKINGDIR/accum/${pretx}.txt" ]; then
      # Call up the chain
      Accumulate_ANTS ${pre}
    fi

    echo "Combining ${pretx} and ${inttx} to form ${newtx}"
	
    # Use the inverse transform if the forward transform does not exist
    if [ ! -f "$STACKINGDIR/tx/${inttx}.txt" ]; then
    
      # linear transform version
      $ANTSDIR/ComposeMultiTransform 2 $STACKINGDIR/accum/${newtx}.txt \
              -R  $STACKINGDIR/accum/linear_fix_${REF_SLICE}_mov_${REF_SLICE}_Affine.txt \
              $STACKINGDIR/accum/${pretx}.txt \
              -i $STACKINGDIR/tx/${intinvtx}.txt 
    
    else
      $ANTSDIR/ComposeMultiTransform 2 $STACKINGDIR/accum/${newtx}.txt \
              $STACKINGDIR/accum/${pretx}.txt \
              $STACKINGDIR/tx/${inttx}.txt 
    fi
  fi
}



Accumulate_FSL()
{
	local new=$1
	local pre=`grep "^$1" < $pathfile | sed -e "s/ /\n/g" | head -n 2 | tail -n 1`
  
	local newtx="linear_fix_${REF_SLICE}_mov_${new}"
	local pretx="linear_fix_${REF_SLICE}_mov_${pre}"
	local inttx="linear_fix_${pre}_mov_${new}"

	if [ ! -f "$STACKINGDIR/accum/${newtx}.mat" ]; then
		if [ ! -f "$STACKINGDIR/accum/${pretx}.mat" ]; then
			# Call up the chain
			Accumulate_FSL $pre
		fi

		echo "Combining ${pretx} and ${inttx} to form ${newtx}"
		    
    # The concatenate order may be wrong check it later 
		$FSLDIR/convert_xfm -omat   "$STACKINGDIR/accum/${newtx}.mat" \
							-concat "$STACKINGDIR/accum/${pretx}.mat" \
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
  $mov $REF_SLICE $mask $ipad
done

qblock "reslice"

# Rebuild the volume
echo "Building a 3D volume [$STACKINGDIR/volume/]"
echo $STACKINGDIR

spacingz=$HSPACEZ

# question: change to Nick's program ConvertImageSeries
$PROGDIR/ConvertImageSeries -o "$STACKINGDIR/volume/reslice_histo.nii.gz" \
                            -sz $spacingz \
                            -in `ls -1 $STACKINGDIR/reslice/*.nii.gz`
$PROGDIR/ConvertImageSeries -o "$STACKINGDIR/volume/mask/reslice_histo_mask.nii.gz" \
                            -sz $spacingz \
                            -in `ls -1 $STACKINGDIR/reslice/mask/*.nii.gz`

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $STACKINGDIR/volume/reslice_histo.nii.gz \
        $STACKINGDIR/volume/reslice_histo_oriented.nii.gz \
        $HISTO_REV_ORIENT

$ANTSDIR/PermuteFlipImageOrientationAxes 3 \
        $STACKINGDIR/volume/mask/reslice_histo_mask.nii.gz \
        $STACKINGDIR/volume/mask/reslice_histo_mask_oriented.nii.gz \
        $HISTO_REV_ORIENT

$C3DDIR/c3d $STACKINGDIR/volume/reslice_histo_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o $STACKINGDIR/volume/reslice_histo_oriented.nii.gz \

$C3DDIR/c3d $STACKINGDIR/volume/mask/reslice_histo_mask_oriented.nii.gz \
            -orient RAI -origin 0x0x0mm \
            -o $STACKINGDIR/volume/mask/reslice_histo_mask_oriented.nii.gz 

# codes for ants deformable (not used here)
		# elif [[ ${STACKING_RECON_PROG} == "ANTS" ]]; then
    # deformable transform version
	  #      echo "-i $STACKINGDIR/tx/${intinvtx}_Affine.txt $STACKINGDIR/tx/${intinvtx}_InverseWarp.nii.gz" \
    #	         `cat $STACKINGDIR/accum/${pretx}.txt` \
		#	     > $STACKINGDIR/accum/${newtx}.txt
# fi



		# elif [[ ${STACKING_RECON_PROG} == "ANTS_DEFORMABLE" ]]; then
			# deformable transform version
	   #    echo "$STACKINGDIR/tx/${inttx}_Warp.txt $STACKINGDIR/tx/${inttx}_Affine.txt" \
    #	        `cat $STACKINGDIR/accum/${pretx}.txt` \
	  # 		     > $STACKINGDIR/accum/${newtx}.txt
	  # 	fi
