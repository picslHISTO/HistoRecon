#!/bin/bash
# Set up the script environment
source ../common.sh

numiter=${H2M_NITER}
echo "Performing MRI-histology matching iteratively, numiter = $numiter"

for ((i=1; i <= ${numiter}; i=i+1))
do
  if (( $i == 1 )); then
    # first iteration, so use original MRI and resliced histology
    echo "Iteration 1 of MRI-histology matching..."

    # directories and names for aligning MRI to histo
    MRI_INDIR="$DATADIR/input/mri_oriented"
    MRI_INNAME="mri"
    MRILABEL_INDIR="$DATADIR/input/mri_oriented/label"
    MRILABEL_INNAME="mri_label"

    HISTO_INDIR="$STACKINGDIR/volume"
    HISTO_INNAME="reslice_histo"
    HISTO_SLICE_INDIR="$STACKINGDIR/reslice"
    HISTO_SLICE_INNAME="reslice_histo_slice"
    HISTOMASK_SLICE_INDIR="$STACKINGDIR/reslice/mask"
    HISTOMASK_SLICE_INNAME="reslice_histo_mask_slice"

    MRI_OUTDIR="$DATADIR/work/mri_to_histo/iter${i}"
    MRI_OUTNAME="affine_MRI_to_histo_iter${i}"
    mkdir -p $MRI_OUTDIR
    
    # directories and names for aligning histo to MRI
    HISTO_OUTDIR="$DATADIR/work/histo_to_mri/iter${i}"
    HISTO_OUTNAME="histo_to_mri"
    mkdir -p $HISTO_OUTDIR

    qsub -pe serial 4 -N "M2H_iter${i}" -o $OUTPUTDIR -e $ERRORDIR itermatch_mri_to_histo.qsub.sh  $HISTO_INDIR $HISTO_INNAME $MRI_INDIR $MRI_INNAME \
    $MRILABEL_INDIR $MRILABEL_INNAME $MRI_OUTDIR $MRI_OUTNAME $i

    qblock
    
    bash itermatch_histo_to_mri.sh  $MRI_OUTDIR $MRI_OUTNAME $HISTO_SLICE_INDIR $HISTO_SLICE_INNAME \
    $HISTOMASK_SLICE_INDIR $HISTOMASK_SLICE_INNAME $HISTO_OUTDIR 

	elif (( $i >= 2 )); then
	
    echo "Iteration $i of MRI-histology matching..."
    let previ=$(($i-1))
       
    # directories and names for aligning MRI to histo
		#MRI_INDIR="$DATADIR/work/mri_to_histo/iter${previ}"
		#MRI_INNAME="affine_MRI_to_histo_iter${previ}"
		#MRILABEL_INDIR="$DATADIR/work/mri_to_histo/iter${previ}/label"
		#MRILABEL_INNAME="affine_MRI_to_histo_iter${previ}_label"
    MRI_INDIR="$DATADIR/input/mri_oriented"
    MRI_INNAME="mri"
    MRILABEL_INDIR="$DATADIR/input/mri_oriented/label"
    MRILABEL_INNAME="mri_label"

		HISTO_INDIR="$DATADIR/work/histo_to_mri/iter${previ}/volume"
		HISTO_INNAME="histo_to_mri"
		HISTO_SLICE_INDIR="$DATADIR/work/histo_to_mri/iter${previ}/reslice"
		HISTO_SLICE_INNAME="inplane_H2M_slice"
		HISTOMASK_SLICE_INDIR="$DATADIR/work/histo_to_mri/iter${previ}/reslice/mask"
		HISTOMASK_SLICE_INNAME="inplane_H2M_mask_slice"


    MRI_INIT_TX="$DATADIR/work/mri_to_histo/iter${previ}/tx/affine_MRI_to_histo_iter${previ}_Affine.txt"
		MRI_OUTDIR="$DATADIR/work/mri_to_histo/iter${i}"
		MRI_OUTNAME="affine_MRI_to_histo_iter${i}"
		mkdir -p $MRI_OUTDIR
		
		# directories and names for aligning histo to MRI
		HISTO_OUTDIR="$DATADIR/work/histo_to_mri/iter${i}"
    mkdir -p $HISTO_OUTDIR
     	
    qsub -pe serial 4 -N "M2H_iter${i}" -o $OUTPUTDIR -e $ERRORDIR itermatch_mri_to_histo.qsub.sh  $HISTO_INDIR $HISTO_INNAME $MRI_INDIR $MRI_INNAME \
    $MRILABEL_INDIR $MRILABEL_INNAME $MRI_OUTDIR $MRI_OUTNAME $i $MRI_INIT_TX

    qblock
    
    bash itermatch_histo_to_mri.sh  $MRI_OUTDIR $MRI_OUTNAME $HISTO_SLICE_INDIR $HISTO_SLICE_INNAME \
    $HISTOMASK_SLICE_INDIR $HISTOMASK_SLICE_INNAME $HISTO_OUTDIR $HISTO_OUTNAME
	fi
done
