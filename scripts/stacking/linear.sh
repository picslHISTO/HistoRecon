#!/bin/bash
# ==============================
# LINEAR registration script (1)
# pairwise registration:
#  register two 2D slices in the neighborhood range
#  ($STACKING_RECON_SEARCH_RANGE)
# ==============================

source ../common.sh

# make sure directories exist
mkdir -p $STACKINGDIR
mkdir -p $STACKINGDIR/tx
mkdir -p $STACKINGDIR/metric
mkdir -p $STACKINGDIR/warp

# make sure directories are clean
rm -f $STACKINGDIR/*.*
rm -f $STACKINGDIR/tx/*.*
rm -f $STACKINGDIR/metric/*.*
rm -f $STACKINGDIR/warp/*.*

echo -e "\nRegistering adjacent slice quintuplets on the cluster..."

# Get a listing of the files into a temp file
listfile=$TMPDIR/listing.txt
maskfile=$TMPDIR/mask.txt

echo "List of files to register stored in $listfile"
ls -1 $GRAYDIR | grep "nii.gz" | sed -e "s/\.nii\.gz//" > $listfile
ls -1 $MASKDIR | grep "nii.gz" | sed -e "s/\.nii\.gz//" > $maskfile

# Iterate over the lines in the file
nfiles=`wc -l < $listfile | sed -e "s/ //g"`
echo -e "Total number of images = $nfiles\n"

cd $SCRIPTDIR/stacking
# perform affine registration
for ((i=1; i < ${nfiles}; i=i+1))
do
  # Get the moving image
  moving=`head -n $i $listfile | tail -n 1`
  
  # Set the upper bound for the inner loop
  let k=i+$STACKING_RECON_SEARCH_RANGE;

  if (( $nfiles < $k ))
  then 
    let k=nfiles; 
  fi

  # Run the inner loop
  for ((j=$i+1; j<=$k; j=j+1))
  do
     fixed=`head -n $j $listfile | tail -n 1`
		 mask=`head -n $j $maskfile | tail -n 1`
		
    exe "linear.mov_${moving}_fix_${fixed}" 1 linear.qsub.sh \
      $fixed $moving $mask 
  done
done

qblock "linear"
