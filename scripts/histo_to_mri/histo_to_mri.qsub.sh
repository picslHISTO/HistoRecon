#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh -o ./output -j y

source /home/liuyang/mouse9/scripts/common.sh




HISTOPATH=$H2MDIR/histo
MRIPATH=$H2MDIR/mri
TXPATH=$H2MDIR/tx
TRGPATH=$H2MDIR/reslice

# Read the command line parameters
mrislice=$1
histoslice=$2
num=$3

echo "histology slice: ${histoslice} --> mri slice: ${mrislice}"  \
 > "$OUTPUTDIR/${histoslice}to${mrislice}.txt"
                               


$FSLDIR/flirt -ref "$MRIPATH/${mrislice}.nii.gz" \
               -in  "$HISTOPATH/${histoslice}.nii.gz" \
							 -out  "$TRGPATH/histo_to_MRI_${num}.nii.gz" \
               -omat "$TXPATH/histo_to_MRI_${num}.mat" \
               -cost normmi \
               -2D \
               -verbose 5 > "$OUTPUTDIR/FLIRT_MRI2H_${mrislice}.txt"
	




#	-refweight "$H2MDIR/mri/mask/${mrimaskslice}.nii.gz" \
            #  -inweight  "$STACKINGDIR/reslice/mask/small/${histoslice}_mask.nii.gz" \

				

