#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

# make directory
mkdir -p $LABELDIR/tx

# clean up the directory
rm -rf $LABELDIR/tx/*.*

nslices=`ls $DEFORMDIR/reslice/label | grep "\.nii\.gz" | wc -l`

for ((i=0; i < $nslices; i++)) 
do
  ipad=`printf %05d $i`
  let num=i+1
  for ((k=$H2M_NITER; k> 0; k--))
  do
    echo '-i' `ls $H2MDIR/iter$k/tx/*.txt | head -n $num | tail -n 1` >> $LABELDIR/tx/label_to_orig_$ipad.txt
  done
  echo '-i' `ls $STACKINGDIR/accum/*.txt | head -n $num | tail -n 1 ` >> $LABELDIR/tx/label_to_orig_$ipad.txt
  echo '-R' `ls $GRAYDIR/*.nii.gz | head -n $num | tail -n 1` >> $LABELDIR/tx/label_to_orig_$ipad.txt

  $ANTSDIR/WarpImageMultiTransform 2 "$DEFORMDIR/reslice/label/2Ddeform_M2H_label_${ipad}.nii.gz" \
                                     "$LABELDIR/label_${ipad}.nii.gz" \
                                     `echo $(cat $LABELDIR/tx/label_to_orig_${ipad}.txt)` \
                                     --use-NN
done


