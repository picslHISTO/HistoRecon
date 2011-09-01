#!/bin/bash
source ../common.sh

$exe "init3D_reg" 1 init3D.qsub.sh

qblock "init3D_reg"
