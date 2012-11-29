#!/bin/sh
# request Bourne shell as shell for job
#$ -cwd -S /bin/sh
# This is the highest-level pipeline for running the rigid registration 

# parse how many steps you want to run in the whole pipeline
step1=False
step2=False
step3=False
step4=False
step5=False
manual=False

if [[ $* == *all* ]]; then 
  step1=True
  step2=True 
  step3=True
  step4=True 
  step5=True
fi
if [[ $* == *1* ]]; then 
  step1=True
fi
if [[ $* == *2* ]]; then 
  step2=True
fi
if [[ $* == *3* ]]; then 
  step3=True
fi
if [[ $* == *4* ]]; then 
  step4=True
fi
if [[ $* == *5* ]]; then 
  step5=True
fi
if [[ $* == *manual* ]]; then 
  manual=True
fi

source "`dirname $0`/common.sh"

if [[ $step1 == True ]]; then
  cd $SCRIPTDIR/preprocess
  # Run the preprocessing of the input data
  bash file_convert.sh
  bash padding.sh
  bash reorient.sh
fi

if [[ $step2 == True ]]; then
  cd $SCRIPTDIR/stacking
  # Run the stacking pipeline
  bash linear.sh
  bash reslice.sh
fi

if [[ $step3 == True ]]; then
  cd $SCRIPTDIR/itermatch
  # Run the iterative histo-MRI registration
  bash init3D.sh
  bash itermatch.sh
fi

if [[ $manual == True ]]; then
  cd $SCRIPTDIR/manMatch
  # Run the slicewise registration between the manually selected histo and MRI blocks
  bash manMatch.sh
fi

if [[ $step4 == True ]]; then
  cd $SCRIPTDIR/deform
  bash histo_to_mri_deform.sh
fi

if [[ $step5 == True ]]; then
  cd $SCRIPTDIR/label_to_orig
  bash label_warp.sh
fi
