#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

# make directory for the accum transform and the upadded image
mkdir -p $LABELDIR/tx
mkdir -p $LABELDIR/padded
mkdir -p $LABELDIR/unpadded
mkdir -p $LABELDIR/orig

# clean up the directory
rm -rf $LABELDIR/*.*
rm -rf $LABELDIR/tx/*.*
rm -rf $LABELDIR/padded/*.*
rm -rf $LABELDIR/unpadded/*.*
rm -rf $LABELDIR/orig/*.*

nslices=`ls $DEFORMDIR/reslice/label | grep "\.nii\.gz" | wc -l`

for ((i=0; i < $nslices; i++)) 
do
  ipad=`printf %05d $i`
  let num=i+1
  qsub -N "label_warp-$ipad" -o $OUTPUTDIR -e $ERRORDIR label_warp.qsub.sh $ipad $num
done

qblock

