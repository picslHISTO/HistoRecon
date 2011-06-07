# Get the general info
source common.sh

cd $SCRIPTDIR/preprocess
# Run the preprocessing of the input data
bash file_convert.sh
bash padding.sh
bash getspacing.sh

cd $SCRIPTDIR/stacking
# Run the stacking pipeline
bash linear.sh
bash reslice.sh

cd $SCRIPTDIR/itermatch
# Run the iterative histo-MRI registration
bash init3D.sh
bash itermatch.sh

cd $SCRIPTDIR/2D_deform
bash mri_to_histo_2D.sh

cd $SCRIPTDIR/label_to_orig
bash label_warp.sh
