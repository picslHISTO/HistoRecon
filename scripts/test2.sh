#!/bin/bash

python parser.py \
      --histo-in /home/liuyang/data/Histo/Rob/1026 \
      --histo-mask-in /home/liuyang/data/Histo/Rob/1026-mask \
      --mri-in /home/liuyang/data/mri/canon_T1_r_halfsize_origin000_masked.nii.gz \
      --mri-label-in /home/liuyang/data/mri/waxholm_label_halfsize_origin000.nii.gz \
      --histo-spacing 0.00504x0.00504x0.150 \
      --data-out /home/liuyang/project/HistoRecon/1026 \
      --ants-dir /home/songgang/project/ANTS/gccrel-st-noFFTW \
      --c3d-dir /home/liuyang/bin/bin \
      --fsl-dir /home/avants/bin/fsl/fsl-4.1.0_32bit/bin \
      --magick-dir /home/liuyang/bin/ImageMagick/bin \
      --h2m-num-iter 2 \
      --m2h-deform-dim 2 \
      --steps 1 2 3 \
      --do-qsub N


