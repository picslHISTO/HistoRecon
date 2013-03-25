#!/bin/sh
#$ -cwd -S /bin/sh
source ../common.sh

# Read the command line parameters
kpad=$1
MRISLICE_INDIR=$2
MRISLICE_INNAME=$3
HISTOSLICE_INDIR=$4
HISTOSLICE_INNAME=$5
HISTOMASKSLICE_INDIR=$6
HISTOMASKSLICE_INNAME=$7
HISTO_OUTDIR=$8

histoslice=${HISTOSLICE_INNAME}$kpad
histomaskslice=${HISTOMASKSLICE_INNAME}$kpad
mrislice=${MRISLICE_INNAME}$kpad

echo "Registering histo slice to MRI slice $kpad"
# here we need a flag for the choice of ANTS or FSL
fix="$MRISLICE_INDIR/${mrislice}.nii.gz"
mov="$HISTOSLICE_INDIR/${histoslice}.nii.gz"
tx="$HISTO_OUTDIR/tx/inplane_H2M_slice${kpad}" 
its=10000x10000x10000

$ANTSDIR/antsRegistration -d 2 \
                    -r [ $fix, $mov, 1 ] \
                    -m MI[ $fix, $mov, 1, 32 ] \
                    -t rigid[ 0.2 ] \
                    -c [$its,1.e-8,20]  \
                    -s 4x2x1vox  \
                    -f 6x4x2 -l 1 -o [ ${tx}_ ] 

# $ANTSDIR/ANTS 2 -m MI["$MRISLICE_INDIR/${mrislice}.nii.gz","$HISTOSLICE_INDIR/${histoslice}.nii.gz",1,32] \
#            	    -o "$HISTO_OUTDIR/tx/inplane_H2M_slice${kpad}_" \
#            	    -i 0 \
#                	--affine-metric-type MI --MI-option 32x10000 \
#                 --rigid-affine true \
#        	        --number-of-affine-iterations 10000x10000x10000

#  	            -t Elast[0.25,0] \
#      	        -r Gauss[12] \
#  	            -i 1000x1000x1000 \


