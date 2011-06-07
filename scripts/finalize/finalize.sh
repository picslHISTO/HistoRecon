#!/bin/bash
source ../common.sh

echo -e "\nApplying transformations to high resolution histology images..."

mkdir -p $FINALDIR/linear/reslice/orig
mkdir -p $FINALDIR/linear/volume/slices/orig
mkdir -p $FINALDIR/histo_to_mri/reslice/orig
mkdir -p $FINALDIR/histo_to_mri/volume
mkdir -p $FINALDIR/deform/slices/orig
mkdir -p $FINALDIR/deform/volume

# Get a listing of the files into a temp file
listfile=$TMPDIR/listing.txt

echo "List of files to register stored in $listfile"
ls -1 $HIGRAYDIR | grep "nii.gz" | sed -e "s/\.nii\.gz//" > $listfile

# Iterate over the lines in the file
slices=(`ls -1 $HIGRAYDIR | grep "\.nii\.gz" | sed -e "s/\.nii\.gz//"`)
nslices=`ls -1 $HIGRAYDIR | grep "\.nii\.gz" | wc -l`

echo -e "Total number of images = $nslices\n"



# We need to ensure that image spacing is consistent between slices,
# so convert all input image and mask spacing to 1x1x1mm

echo "Setting spacing of histology images..."
##################### SHOULD SET SPACING TO BE HIHSPACEX, HIHSPACEY, etc... not 1x1

											if (( 1==0 )); then

for i in $HIGRAYDIR/*.nii.gz
do
   a=`basename $i .nii.gz`
   echo "Fixing spacing of ${HIGRAYDIR}/${a}"
   $C3DDIR/c2d $HIGRAYDIR/${a}.nii.gz -spacing 0.2x0.2mm -type float -o $HIGRAYDIR/${a}.nii.gz
done

echo "Reslice histology images for reconstruction step..."

# The user can specify a slice used as the reference.
# If not, we will select the half-way slice as the reference
if [ ! $REFERENCE_SLICE ]; then
	echo -e "\n**No reference slice supplied!**\n"
	iref=`expr $nslices / 2`
	REFERENCE_SLICE=${slices[${iref}]}
fi

echo -e "Using $REFERENCE_SLICE as the reference\n"

for ((i=1; i<=nslices; i++))
do
	tx=`ls -1 $LINEARDIR/accum | grep ".txt" | head -n $i | tail -n 1 | sed -e "s/\.txt//"`
	mov=`ls -1 $HIGRAYDIR | grep "\.nii\.gz" | head -n $i | tail -n 1 | sed -e "s/\.nii\.gz//"`
	qsub -N "reslice_hires.$i" -o $OUTPUTDIR -e $ERRORDIR $SCRIPTDIR/finalize/reslice_hires.qsub.sh $mov $REFERENCE_SLICE $tx    
done

qblock

# Compute a whole volume
echo "Building a 3D volume [$FINALDIR/linear/volume/reslice_histo.nii.gz]"

$PROGDIR/imageSeriesToVolume -o "$FINALDIR/linear/volume/reslice_histo.nii.gz" \
                             -sx $HIHSPACEX -sy $HIHSPACEY -sz $HIHSPACEZ \
                             -i `ls -1 $FINALDIR/linear/reslice/orig/*.nii.gz`


# number of blank padding slices
P=3

# pad with three zero slices on top and bottom
$C3DDIR/c3d "$FINALDIR/linear/volume/reslice_histo.nii.gz" \
            -pad 0x0x${P}vox 0x0x${P}vox 0 \
    	-o "$FINALDIR/linear/volume/reslice_histo.nii.gz"


# extract the slices of the padded images (needed for future histo_to_mri registration step)
nslices=`$C3DDIR/c3d $FINALDIR/linear/volume/reslice_histo.nii.gz -info-full \
        | grep "Image Dimensions" | sed -e "s/.*, //" | sed -e "s/]//"`

for ((i=0; i < ${nslices}; i=i+1))
do
	formati=`printf "%05d" $i`
	echo "Extracting slice $formati"
   
	$C3DDIR/c3d "$FINALDIR/linear/volume/reslice_histo.nii.gz" \
				-slice z $i \
				-o "$FINALDIR/linear/volume/slices/orig/reslice_histo_${formati}.nii.gz"
done

										

numiter=4
echo "Transforming histology to MRI, numiter = $numiter"

nslicespad=`ls -1 $FINALDIR/linear/volume/slices/orig | grep "\.nii\.gz" | wc -l`

for ((k=0; k < ${nslicespad}; k=k+1))
do
	kpad=`printf "%05d" $k`	
	echo "Slice = $kpad"

	# do not register first and last three slices of histology to MRI, since those histo slices are black
	if (( k < 3 )) || (( k >= nslicespad-3 ))
	then
		# copy black slices to new directory
		cp "$FINALDIR/linear/volume/slices/orig/reslice_histo_${kpad}.nii.gz" "$FINALDIR/histo_to_mri/reslice/orig/inplane_histo_to_MR_${kpad}.nii.gz"
	else
		# generate list of histo_to_mri transform names
		h2m_tx=" "
		for ((i=1; i <= ${numiter}; i=i+1)); do
			h2m_tx="${h2m_tx} $DATADIR/work/histo_to_mri/iter${i}/tx/inplane_histo_to_MR_${kpad}_Affine.txt"
		done

		mkdir -p $DATADIR/work/histo_to_mri/iter${numiter}/tx_concat
		echo ${h2m_tx} > "$DATADIR/work/histo_to_mri/iter${numiter}/tx_concat/h2m_tx_${kpad}.txt"
		
		qsub -N "warp_h2m_hires.${k}" -o $OUTPUTDIR -e $ERRORDIR $SCRIPTDIR/finalize/warp_h2m_hires.qsub.sh $kpad "$DATADIR/work/histo_to_mri/iter${numiter}/tx_concat/h2m_tx_${kpad}.txt"
	fi
done

qblock

							
# Compute a whole volume
echo "Building a 3D volume [ $FINALDIR/histo_to_mri/volume/histo_to_mri.nii.gz ]"

$PROGDIR/imageSeriesToVolume -o "$FINALDIR/histo_to_mri/volume/histo_to_mri.nii.gz" \
                             -sx $HIHSPACEX -sy $HIHSPACEY -sz $HIHSPACEZ \
                             -i `ls -1 $FINALDIR/histo_to_mri/reslice/orig/*.nii.gz`


								fi
								
								
# number of blank padding slices
P=3

# number of bad slices at start of stack
badstart=0

# number of bad slices at end of stack
badend=2

# number of deformable iterations to run
numdefiter=4

nslicespad=`ls -1 $FINALDIR/linear/volume/slices/orig | grep "\.nii\.gz" | wc -l`

for ((j=P; j < $((nslicespad-P)); j=j+1))
do
	curr=`printf %05d $((j))`
	
	histodef_tx=" "
	for ((i=1; i <= ${numdefiter}; i=i+1)); do
		histodef_tx="${histodef_tx} $DATADIR/work/deform/iter${i}/tx/inplane_histo_to_MR_${curr}_Warp.nii.gz $DATADIR/work/deform/iter${i}/tx/inplane_histo_to_MR_${curr}_Affine.txt"
	done

	mkdir -p $DATADIR/work/deform/iter${numdefiter}/tx_concat
	echo ${histodef_tx} > "$DATADIR/work/deform/iter${numdefiter}/tx_concat/histodef_tx_${curr}.txt"

#	qsub -N "deform_warp.$curr" -o $OUTPUTDIR -e $ERRORDIR histo_deform_hires.qsub.sh $curr "$DATADIR/work/deform/iter${numdefiter}/tx_concat/histodef_tx_${curr}.txt"
#	bash histo_deform_hires.qsub.sh $curr "$DATADIR/work/deform/iter${numdefiter}/tx_concat/histodef_tx_${curr}.txt"
done

qblock


HISTO_INDIR="$FINALDIR/histo_to_mri/reslice"
HISTO_OUTDIR="$FINALDIR/deform/slices"
HISTOSLICE_NAME="inplane_histo_to_MR_"

###	if ((j < $P )) || ((

# copy first and last P black slices
for ((j=0; j < $P; j=j+1))
do
	slice_start=`printf %05d $j`
	slice_end=`printf %05d $((nslicespad-1-$j))`

	cp "$HISTO_INDIR/orig/${HISTOSLICE_NAME}${slice_start}.nii.gz" "$HISTO_OUTDIR/orig/${HISTOSLICE_NAME}${slice_start}.nii.gz"
	cp "$HISTO_INDIR/orig/${HISTOSLICE_NAME}${slice_end}.nii.gz"   "$HISTO_OUTDIR/orig/${HISTOSLICE_NAME}${slice_end}.nii.gz"
done


# stack slices to volume

$PROGDIR/imageSeriesToVolume -o "$FINALDIR/deform/volume/histo_deform.nii.gz" \
   	                         -sx $HIHSPACEX -sy $HIHSPACEY -sz $HIHSPACEZ \
       	                     -i `ls -1 $HISTO_OUTDIR/orig/*.nii.gz`
