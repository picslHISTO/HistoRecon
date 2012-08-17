#!/bin/bash

python parser.py \
      --histo-in /home/liuyang/mouse_David \
      --mri-in /home/liuyang/data/mri/canon_T1_r_halfsize_origin000_masked.nii.gz \
      --mri-label-in /home/liuyang/data/mri/waxholm_label_halfsize_origin000.nii.gz \
      --histo-spacing 0.000457x0.000457x0.090 \
      --data-out /home/liuyang/project/HistoRecon/David \
      --ants-dir /home/songgang/project/ANTS/gccrel-Jan-18-2012/Examples \
      --c3d-dir /home/liuyang/bin/bin \
      --fsl-dir /home/avants/bin/fsl/fsl-4.1.0_32bit/bin \
      --magick-dir /home/liuyang/bin/ImageMagick/bin \
      --matlab-dir /mnt/pkg/matlab_r2009b/bin \
      --h2m-num-iter 2 \
      --m2h-deform-dim 2 \
      --steps 1 2 3

      # --do-qsub N \
