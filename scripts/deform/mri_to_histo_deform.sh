#!/bin/bash
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
MRILABEL_SLICE_INDIR="$M2HDIR/iter${H2M_NUM_ITER}/slices/label"
MRI_SLICE_INNAME="affine_MRI_to_histo_iter${H2M_NUM_ITER}_slice"
MRILABEL_SLICE_INNAME="affine_MRI_to_histo_iter${H2M_NUM_ITER}_label_slice"
MRI_VOLUME_INDIR="$DATADIR/input/mri_oriented"
MRI_VOLUME_INNAME="mri"
MRILABEL_VOLUME_INDIR="$DATADIR/input/mri_oriented/label"
MRILABEL_VOLUME_INNAME="mri_label"

TX_INIT_DIR="$M2HDIR/iter${H2M_NUM_ITER}/tx"
TX_INIT_NAME="affine_MRI_to_histo_iter${H2M_NUM_ITER}_Affine.txt"
TX_DIR="$DEFORMDIR/tx"

MRI_VOLUME_OUTDIR="$DEFORMDIR/volume"
MRILABEL_VOLUME_OUTDIR="$DEFORMDIR/volume/label"
MRI_SLICE_OUTDIR="$DEFORMDIR/reslice"
MRILABEL_SLICE_OUTDIR="$DEFORMDIR/reslice/label"

# Make sure directories exist
mkdir -p $MRI_VOLUME_OUTDIR
mkdir -p $MRILABEL_VOLUME_OUTDIR
mkdir -p $MRI_SLICE_OUTDIR
mkdir -p $MRILABEL_SLICE_OUTDIR
mkdir -p $TX_DIR

rm -rf $MRI_VOLUME_OUTDIR/*.*
rm -rf $MRILABEL_VOLUME_OUTDIR/*.*
rm -rf $MRI_SLICE_OUTDIR/*.*
rm -rf $MRILABEL_SLICE_OUTDIR/*.*
rm -rf $TX_DIR/*.*

if ((${M2H_DEFORM_DIM}==3)); then
  
  echo "Registering MRI volume to corresponding histology volume"
  # qsub -N "deform3D" -pe serial 4 -o $OUTPUTDIR -e $ERRORDIR mri_to_histo_3D.qsub.sh \
  exe "deform3D" 4 mri_to_histo_3D.qsub.sh \
    ${HISTO_VOLUME_INDIR} ${HISTO_VOLUME_INNAME} \
    ${MRI_VOLUME_INDIR} ${MRI_VOLUME_INNAME} ${MRILABEL_VOLUME_INDIR} ${MRILABEL_VOLUME_INNAME} \
    ${TX_INIT_DIR} ${TX_INIT_NAME} ${TX_DIR}\
    ${MRI_VOLUME_OUTDIR} ${MRILABEL_VOLUME_OUTDIR} ${MRI_SLICE_OUTDIR} ${MRILABEL_SLICE_OUTDIR}

  qblock "deform3D"

elif ((${M2H_DEFORM_DIM}==2)); then

  # Submit a job for every image in the source directory
  echo "Registering MR slices to corresponding histology slices"

  nslices=`ls -1 ${MRI_SLICE_INDIR} | grep "\.nii\.gz" | wc -l`

  for ((k=0;k<nslices;k++))
  do
    kpad=`printf %05d $k`

    exe "deform2D" 1 mri_to_histo_2D.qsub.sh \
    ${HISTO_SLICE_INDIR} ${HISTO_SLICE_INNAME} ${HISTOMASK_SLICE_INDIR} ${HISTOMASK_SLICE_INNAME}\
    ${TX_DIR} \
    ${MRI_SLICE_INDIR} ${MRI_SLICE_INNAME} ${MRILABEL_SLICE_INDIR} ${MRILABEL_SLICE_INNAME} \
    ${MRI_SLICE_OUTDIR} ${MRILABEL_SLICE_OUTDIR} ${kpad}
  done

  qblock "deform2D"

  echo "Building a 3D volume [ $H2MDIR/volume/inplane_MR_to_histo.nii.gz ]"

  # Get the information for spacing
  spacingx=$HSPACEX
  spacingy=$HSPACEY
  spacingz=$HSPACEZ
  orient=${HISTO_ORIENT}
  flip=${HISTO_FLIP}

  if [ -n "$flip" ] 
  then
    flip_option="-flip $flip"
  else
    flip_option=''
  fi

  $PROGDIR/imageSeriesToVolume -o "${MRI_VOLUME_OUTDIR}/inplane_M2H.nii.gz" \
                               -sx $spacingx -sy $spacingy -sz $spacingz \
                               -i `ls -1 ${MRI_SLICE_OUTDIR}/*.nii.gz`

  $PROGDIR/imageSeriesToVolume -o "${MRILABEL_VOLUME_OUTDIR}/inplane_M2H_label.nii.gz" \
                               -sx $spacingx -sy $spacingy -sz $spacingz \
                               -i `ls -1 ${MRILABEL_SLICE_OUTDIR}/*.nii.gz`

  $C3DDIR/c3d ${MRI_VOLUME_OUTDIR}/inplane_M2H.nii.gz \
              $flip_option \
          -pa $orient \
      -orient RAI -origin 0x0x0mm \
           -o ${MRI_VOLUME_OUTDIR}/inplane_M2H_oriented.nii.gz 

  $C3DDIR/c3d ${MRILABEL_VOLUME_OUTDIR}/inplane_M2H_label.nii.gz \
              $flip_option \
          -pa $orient \
      -orient RAI -origin 0x0x0mm \
           -o ${MRILABEL_VOLUME_OUTDIR}/inplane_M2H_label_oriented.nii.gz 
fi
