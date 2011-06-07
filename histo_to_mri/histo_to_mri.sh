#!/bin/bash
# Set up the script environment
source /home/liuyang/mouse10/scripts/common.sh

HISTOPATH="$H2MDIR/histo"
MRIPATH="$H2MDIR/mri"
TXPATH="$H2MDIR/tx"

# Make sure directories exist
mkdir -p $TXPATH

# make sure directories are clean
rm -f $TXPATH/*.*

echo "Registering histology slices to corresponding MR slices"
# Submit a job for every image in the source directory
nslices=`ls -1 $MRIPATH | grep "\.nii\.gz" | wc -l`

for ((i=1;i<=nslices;i++))
do
	mrislice=`ls -1 $MRIPATH | grep "\.nii\.gz" | head -n $i | tail -n 1 | sed -e "s/\.nii\.gz//"`
	histoslice=`ls -1 $HISTOPATH | grep "\.nii\.gz" | head -n $i | tail -n 1 | sed -e "s/\.nii\.gz//"`
	num=`printf "%05d" $i`
  qsub -N "H2M${i}" -o $OUTPUTDIR -e $ERRORDIR \
	$SCRIPTDIR/histo_to_mri/histo_to_mri.qsub.sh $mrislice $histoslice $num

done

qblock
