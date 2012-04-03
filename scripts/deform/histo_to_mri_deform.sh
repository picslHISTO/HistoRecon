#!/bin/bash
#$ -cwd -S /bin/sh

# Set up the script environment
source ../common.sh

HISTO_SLICE_INDIR="$H2MDIR/iter${H2M_NUM_ITER}/reslice"
HISTOMASK_SLICE_INDIR="$H2MDIR/iter${H2M_NUM_ITER}/reslice/mask"
HISTO_SLICE_INNAME="inplane_H2M_slice"
HISTOMASK_SLICE_INNAME="inplane_H2M_mask_slice"
HISTO_VOLUME_INDIR="$H2MDIR/iter${H2M_NUM_ITER}/volume"
HISTO_VOLUME_INNAME="histo_to_mri"
HISTOMASK_VOLUME_INDIR="$H2MDIR/iter${H2M_NUM_ITER}/volume/mask"
HISTOMASK_VOLUME_INNAME="histo_to_mri_mask"

MRI_SLICE_INDIR="$M2HDIR/iter${H2M_NUM_ITER}/slices"
MRI_SLICE_INNAME="affine_MRI_to_histo_iter${H2M_NUM_ITER}_slice"
MRI_VOLUME_INDIR="$M2HDIR/iter${H2M_NUM_ITER}"
MRI_VOLUME_INNAME="affine_MRI_to_histo_iter${H2M_NUM_ITER}"

TX_INIT_DIR="$M2HDIR/iter${H2M_NUM_ITER}/tx"
TX_INIT_NAME="affine_MRI_to_histo_iter${H2M_NUM_ITER}_Affine.txt"
TX_DIR="$DEFORMDIR/tx"

HISTO_VOLUME_OUTDIR="$DEFORMDIR/volume"
HISTOMASK_VOLUME_OUTDIR="$DEFORMDIR/volume/mask"
HISTO_SLICE_OUTDIR="$DEFORMDIR/reslice"
HISTOMASK_SLICE_OUTDIR="$DEFORMDIR/reslice/mask"

# Make sure directories exist
mkdir -p $HISTO_VOLUME_OUTDIR
mkdir -p $HISTOMASK_VOLUME_OUTDIR
mkdir -p $HISTO_SLICE_OUTDIR
mkdir -p $HISTOMASK_SLICE_OUTDIR
mkdir -p $TX_DIR

rm -rf $HISTO_VOLUME_OUTDIR/*.*
rm -rf $HISTOMASK_VOLUME_OUTDIR/*.*
rm -rf $HISTO_SLICE_OUTDIR/*.*
rm -rf $HISTOMASK_SLICE_OUTDIR/*.*
rm -rf $TX_DIR/*.*

if ((${M2H_DEFORM_DIM}==3)); then
  
  echo "Registering MRI volume to corresponding histology volume"
  # qsub -N "deform3D" -pe serial 4 -o $OUTPUTDIR -e $ERRORDIR mri_to_histo_3D.qsub.sh \
  exe "deform3D" 4 histo_to_mri_3D.qsub.sh \
    ${MRI_VOLUME_INDIR} ${MRI_VOLUME_INNAME} \
    ${HISTO_VOLUME_INDIR} ${HISTO_VOLUME_INNAME} ${HISTOMASK_VOLUME_INDIR} ${HISTOMASK_VOLUME_INNAME} \
    ${TX_DIR} \
    ${HISTO_VOLUME_OUTDIR} ${HISTOMASK_VOLUME_OUTDIR}  

  qblock "deform3D"

elif ((${M2H_DEFORM_DIM}==2)); then
  # Submit a job for every image in the source directory
  echo "Registering histology slices to corresponding MR slices"

  nslices=`ls -1 ${HISTO_SLICE_INDIR} | grep "\.nii\.gz" | wc -l`

  for ((k=0;k<nslices;k++));do
    kpad=`printf %05d $k`

    exe "histo_deform2D" 1 histo_to_mri_2D.qsub.sh \
    ${HISTO_SLICE_INDIR} ${HISTO_SLICE_INNAME} ${HISTOMASK_SLICE_INDIR} ${HISTOMASK_SLICE_INNAME}\
    ${MRI_SLICE_INDIR} ${MRI_SLICE_INNAME} \
    ${TX_DIR} \
    ${HISTO_SLICE_OUTDIR} ${HISTOMASK_SLICE_OUTDIR} ${kpad}
  done

  qblock "histo_deform2D"

  echo "Building a 3D volume [ $H2MDIR/volume/inplane_MR_to_histo.nii.gz ]"

  # Get the information for spacing
  spacingx=$RESPACEX
  spacingy=$RESPACEY
  spacingz=$HSPACEZ

  $PROGDIR/imageSeriesToVolume -o "${HISTO_VOLUME_OUTDIR}/inplane_H2M.nii.gz" \
                               -sx $spacingx -sy $spacingy -sz $spacingz \
                               -i `ls -1 ${HISTO_SLICE_OUTDIR}/*.nii.gz`

  $PROGDIR/imageSeriesToVolume -o "${HISTOMASK_VOLUME_OUTDIR}/inplane_H2M_mask.nii.gz" \
                               -sx $spacingx -sy $spacingy -sz $spacingz \
                               -i `ls -1 ${HISTOMASK_SLICE_OUTDIR}/*.nii.gz`


  $ANTSDIR/PermuteFlipImageOrientationAxes 3 \
          ${HISTO_VOLUME_OUTDIR}/inplane_H2M.nii.gz \
          ${HISTO_VOLUME_OUTDIR}/inplane_H2M_oriented.nii.gz \
          $HISTO_REV_ORIENT

  $ANTSDIR/PermuteFlipImageOrientationAxes 3 \
          ${HISTOMASK_VOLUME_OUTDIR}/inplane_H2M_mask.nii.gz \
          ${HISTOMASK_VOLUME_OUTDIR}/inplane_H2M_mask_oriented.nii.gz \
          $HISTO_REV_ORIENT

  $C3DDIR/c3d ${HISTO_VOLUME_OUTDIR}/inplane_H2M_oriented.nii.gz \
              -orient RAI -origin 0x0x0mm \
              -o ${HISTO_VOLUME_OUTDIR}/inplane_H2M_oriented.nii.gz 

  $C3DDIR/c3d ${HISTOMASK_VOLUME_OUTDIR}/inplane_H2M_mask_oriented.nii.gz \
              -orient RAI -origin 0x0x0mm \
              -o ${HISTOMASK_VOLUME_OUTDIR}/inplane_H2M_mask_oriented.nii.gz 
fi
