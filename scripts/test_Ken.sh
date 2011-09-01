#!/bin/bash

python parser.py \
     --histo-in /home/liuyang/data/Histo/Ken/case_34slices/data/output/shrink/blue \
     --histo-mask-in /home/liuyang/data/Histo/Ken/case_34slices/data/output/shrink/bluemask \
     --mri-in /home/liuyang/data/mri/canon_T1_r_halfsize_origin000_masked_half.nii.gz \
     --mri-label-in /home/liuyang/data/mri/waxholm_label_halfsize_origin000_half.nii.gz \
     --histo-spacing 0.05384x0.05384x0.1 \
     --histo-resize-ratio 100% \
     --histo-flip xy \
     --histo-permute-axis zxy \
     --data-out /home/liuyang/project/HistoRecon/Ken_34 \
     --ants-dir /home/songgang/project/ANTS/gccrel-st-noFFTW \
     --c3d-dir /home/liuyang/bin/bin \
     --fsl-dir /home/avants/bin/fsl/fsl-4.1.0_32bit/bin \
     --magick-dir /home/liuyang/bin/ImageMagick/bin \
     --h2m-num-iter 2 \
     --m2h-deform-dim 2 \
     --steps 1 \
     --do-qsub Y

