#!/bin/bash
source ../common.sh
qsub -N "init3D-reg" -o $OUTPUTDIR -e $ERRORDIR init3D.qsub.sh

qblock
