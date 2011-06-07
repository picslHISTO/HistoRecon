#!/bin/bash
# Set up the script environment
#$ -cwd -S /bin/sh -o ./output -j y
source ../common.sh

TX_PATH=$H2MDIR/iter1/tx

bash smooth_h2m_transforms.sh ${TX_PATH}
