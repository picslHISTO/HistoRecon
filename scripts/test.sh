#!/bin/bash

python parser.py \
      --histo-in /home/liuyang/data/Histo/Rob/1034 \
      --histo-mask-in /home/liuyang/data/Histo/Rob/1034-mask \
      --mri-in /home/liuyang/data/mri/canon_T1_r_halfsize_origin000_masked.nii.gz \
      --mri-label-in /home/liuyang/data/mri/waxholm_label_halfsize_origin000.nii.gz \
      --histo-orient RSP \
      --histo-spacing 0.00054x0.00054x0.165 \
      --data-out /home/liuyang/project/HistoRecon/1034 \
      --ants-dir /home/songgang/project/ANTS/gccrel-st-noFFTW \
      --c3d-dir /home/liuyang/bin/bin \
      --fsl-dir /home/avants/bin/fsl/fsl-4.1.0_32bit/bin \
      --magick-dir /home/liuyang/bin/ImageMagick/bin \
      --steps 3

