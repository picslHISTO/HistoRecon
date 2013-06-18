#!usr/bin/python

import re
import os
import sys
import argparse
import subprocess
import glob

# function for getting the orientation of the image correct
# this function telling you what transform gives the current orientation from RAI
def threeD_orient(RAI_orient):
  orientList=[['R','L'],['A','P'],['I','S']]
  # first check whether the input is a three letter long argument
  if ( len(RAI_orient) != 3):
    print "The orientation should be 3 letters"
    return
  # pa is the permuting of the axis, flip is the flipping of the axis
  pa = []
  flip = []
  for letter in RAI_orient.upper():
    for i in range(3):
      for j in range(2):
        if letter == orientList[i][j]:
          pa.append(i)
          flip.append(j)
          continue
  if (sorted(pa) != [0,1,2]):
    print "Wrong orientation input"
    return 
  return pa + flip

# this gives the orientation for the reverse of the orientation 
def rev_orient(orient_in):
  # extract components 
  pa_in = orient_in[0:3]  
  flip_in = orient_in[3:6]
  pa = range(3)
  # invert the orientation and change the flip 
  for i in range(3):
    pa[pa_in[i]] = i
  flip = [flip_in[i] for i in pa]
  return pa + flip


# function to read the import and the input directories and output directories
def main(argv=sys.argv):

  # check the directory of the parser file 
  scripts_dir=os.path.abspath(os.path.dirname(argv[0]))

  parser = argparse.ArgumentParser()
  # histology and mask input directory
  parser.add_argument('--histo-in', 
      help='histology input raw directory',
      required = True)
  parser.add_argument('--histo-mask-in', 
      help='histology mask input raw directory',
      default = "")

  # histology input spacing, orientation 
  parser.add_argument('--histo-spacing', 
      help='the spacing info of the histology image, e.g. 3x3x2',
      required = True)
  parser.add_argument('--histo-orient', 
      help='orientation of histology 3D image, e.g. SRP',
      required = True)

  # mri and label input directory
  parser.add_argument('--mri-in', 
      help='mri Waxholm file',
      required = True)
  parser.add_argument('--mri-label-in', 
      help='mri Waxholm label file',
      required = True)

  # dataset name 
  parser.add_argument('--data-out', 
      help='data output directory',
      required = True)

  # binary and program directory
  parser.add_argument('--ants-dir', 
      help='ANTS binary directory',
      required = True)
  parser.add_argument('--fsl-dir', 
      help='FSL binary directory',
      default = "")
# may need to add a fsl scheme directory here in order for the fsl to work 
  parser.add_argument('--c3d-dir', 
      help='c3d binary directory',
      required = True)
  parser.add_argument('--magick-dir', 
      help='ImageMagick binary directory',
      required = True)
  parser.add_argument('--matlab-dir', 
      help='MATLAB binary directory',
      default = "")
  parser.add_argument('--prog-dir', 
      help='program binary directory',
      default = os.path.abspath(os.path.join(scripts_dir,'../progs/bin')))

  # histology input resize, orientation, spacing and padding info
  parser.add_argument('--histo-resize-ratio', 
      help='histology image resize ratio, e.g. 5%%', 
      default = '5%')
  parser.add_argument('--histo-pad-percent', 
      help='histo pad percent, e.g. 30',
      default = '30')

  # stacking parameters
  parser.add_argument('--histo-stacking-range', 
      help='histology slices pairwise registration search range',
      default = '5')
  parser.add_argument('--histo-stacking-prog', 
      help='histology slices stacking binary program to use (ANTS / FSL)',
      default = 'ANTS')
  parser.add_argument('--histo-stacking-dof', 
      help='histology slices stacking linear registration degree of freedom (3 (rigid) / 6 (affine))',
      default = '3')

  # histology-MRI itermatch
  parser.add_argument('--h2m-num-iter', 
      help='histology to mri number of iterations',
      default = '4')
  parser.add_argument('--m2h-prog', 
      help='mri to histology 3D affine registration binary program to use (ANTS / FSL)',
      default = 'ANTS_LINEAR')
  parser.add_argument('--h2m-smooth-sigma', 
      help='Gaussian smooth parameter for histology to mri transform',
      default = '2')

  # histology-MRI manual match
  parser.add_argument('--manual-histo-index', 
      help='manual histology index (start end, requires 2 arguments)',
      nargs = 2,
      default = ['0','0'])
  parser.add_argument('--manual-mri-index', 
      help='manual mri index (start end, requires 2 arguments)',
      nargs = 2,
      default = ['0','0'])

  # MRI-histology deformable 
  parser.add_argument('--m2h-deform-dim', 
      help='mri to histology deformable registration dimension (2 (slicewise) / 3)',
      default = '3')
  # execution steps 
  parser.add_argument('--steps', 
      nargs='+',
      help='Choose the steps in the pipeline you want to run,\n e.g. --steps 1 2 3',
      default = 'all')
  # qsub option
  parser.add_argument('--do-qsub',
      help='whether to use qsub in the whole pipeline (Y/N)',
      default = 'Y')

  # parse the input options
  args = parser.parse_args()

  scripts_out = os.path.join(args.data_out,'scripts')

  # make the target directory and the copy the code over
  subprocess.call(['mkdir','-p',scripts_out])
  subprocess.call(['cp','-rt',scripts_out] + glob.glob(os.path.join(scripts_dir,'*')))

  print "copy the scripts to " + scripts_out
  filename= os.path.join(scripts_out,'opt.sh')
  f_out=open(filename,'w')

  histo_rawdir=os.path.abspath(args.histo_in)
  histomask_rawdir=os.path.abspath(args.histo_mask_in)
    

  mri_waxholm_file=os.path.abspath(args.mri_in)
  mrilabel_waxholm_file=os.path.abspath(args.mri_label_in)

  f_out.writelines('# Set up script environment \n')
  f_out.writelines('#!/bin/bash \n') 

  f_out.writelines('# histo raw data input directory \n')
  f_out.writelines('HISTO_RAWDIR=' + histo_rawdir + '\n')
  if (args.histo_mask_in != ""):
    f_out.writelines('HISTOMASK_RAWDIR=' + histomask_rawdir + '\n')

  histo_spacing = args.histo_spacing.split('x')
  f_out.writelines('# input histology spacing info \n')
  f_out.writelines('HSPACEX=' + histo_spacing[0] + '\n')
  f_out.writelines('HSPACEY=' + histo_spacing[1] + '\n')
  f_out.writelines('HSPACEZ=' + histo_spacing[2] + '\n')

  f_out.writelines('# histology orientation info \n')
  histo_orient = threeD_orient(args.histo_orient)
  histo_rev_orient = rev_orient(histo_orient)
  histo_orient_str = ' '.join([str(num) for num in histo_orient])
  histo_rev_orient_str = ' '.join([str(num) for num in histo_rev_orient])
  f_out.writelines('HISTO_ORIENT=\"' + histo_orient_str + '\"\n')
  f_out.writelines('HISTO_REV_ORIENT=\"' + histo_rev_orient_str + '\"\n')

  f_out.writelines('# MRI Waxholm directory \n')
  f_out.writelines('MRI_WAXHOLM_FILE=' + mri_waxholm_file + '\n') 
  f_out.writelines('MRILABEL_WAXHOLM_FILE=' + mrilabel_waxholm_file + '\n')

  f_out.writelines('# output working directory \n')
  f_out.writelines('BASEDIR=' + args.data_out + '\n')

  f_out.writelines('ANTSDIR=' + args.ants_dir + '\n')
  f_out.writelines('C3DDIR=' + args.c3d_dir + '\n')
  f_out.writelines('FSLDIR=' + args.fsl_dir + '\n')
  f_out.writelines('MAGICKDIR=' + args.magick_dir + '\n')
  f_out.writelines('MATLABDIR=' + args.matlab_dir + '\n')
  f_out.writelines('PROGDIR=' + args.prog_dir + '\n')

  f_out.writelines('# histology resize and pad info \n')
  f_out.writelines('HISTO_RESIZE_RATIO=' + args.histo_resize_ratio + '\n')
  f_out.writelines('HISTO_PAD_PERCENT=' + args.histo_pad_percent + '\n')

  # change the histology spacing info by the ratio given
  # convert the percentage into the real float 
  histo_resize_ratio = float(args.histo_resize_ratio.strip('%')) * 0.01
  histo_spacing[0] = str( float(histo_spacing[0]) / histo_resize_ratio )
  histo_spacing[1] = str( float(histo_spacing[1]) / histo_resize_ratio )

  f_out.writelines('# resized histology spacing info \n')
  f_out.writelines('RESPACEX=' + histo_spacing[0] + '\n')
  f_out.writelines('RESPACEY=' + histo_spacing[1] + '\n')

  f_out.writelines('# histology stacking recon parameters \n')
  f_out.writelines('STACKING_RECON_SEARCH_RANGE=' + args.histo_stacking_range + '\n')
  f_out.writelines('STACKING_RECON_PROG=' + args.histo_stacking_prog + '\n')
  f_out.writelines('STACKING_RECON_DOF=' + args.histo_stacking_dof + '\n')

  # manual matching
  f_out.writelines('# manual registration histology index' + '\n')
  f_out.writelines('MANUAL_HISTO_INDEX_START=' + args.manual_histo_index[0] + '\n')
  f_out.writelines('MANUAL_HISTO_INDEX_END=' + args.manual_histo_index[1] + '\n')

  f_out.writelines('# manual registration histology index' + '\n')
  f_out.writelines('MANUAL_MRI_INDEX_START=' + args.manual_mri_index[0] + '\n')
  f_out.writelines('MANUAL_MRI_INDEX_END=' + args.manual_mri_index[1] + '\n')

  # itermatch
  f_out.writelines('# itermatch \n')
  f_out.writelines('H2M_NUM_ITER=' + args.h2m_num_iter + '\n')
  f_out.writelines('M2H_PROG=' + args.m2h_prog + '\n')
  f_out.writelines('H2M_SMOOTH_SIGMA=' + args.h2m_smooth_sigma + '\n')

  f_out.writelines('# deformable \n')
  f_out.writelines('M2H_DEFORM_DIM=' + args.m2h_deform_dim + '\n')

  f_out.writelines('# qsub option \n')
  f_out.writelines('DO_QSUB=' + args.do_qsub + '\n')
  f_out.close()

  # concatenate the opt.sh file to the original common.sh file 
  f_common_in = open(os.path.join(scripts_dir,'common.sh'),'r')
  # note use 'w' will overwrite the file
  f_common_out = open(os.path.join(scripts_out,'common.sh'),'w')
  f_opt = open(os.path.join(scripts_out,'opt.sh'),'r')
  f_common_out.write(f_opt.read())
  f_common_out.write(f_common_in.read())

  f_opt.close()
  f_common_in.close()
  f_common_out.close()

  # run the pipeline
   
  subprocess.call(['bash', os.path.join(scripts_out,'entire_pipeline.sh')] + list(args.steps))
   
  
if __name__ == "__main__":
  main()
