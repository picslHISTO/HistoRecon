#!/bin/bash

# to initialize the 3D affine registration between atlas and user volume
# currently, for Rob William's data, we use "half binary mask" 
# this is very data specific
# this will ge replaced by a new version soon

source ../common.sh
qsub -N "init3D-reg" -o $OUTPUTDIR -e $ERRORDIR init3D.qsub.sh

qblock
