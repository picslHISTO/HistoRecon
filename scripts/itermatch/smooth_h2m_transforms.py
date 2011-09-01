#!/usr/bin/python

import re
import sys
import os
import math

# function to read ants file (of a rigid transformation) and returns a list of parameters
def ants2rigid(antsFile):
  f_in = open(antsFile,'rU')
  antsStr = f_in.read()
  # rigid parameters
  rigidLine = re.findall(r"^Parameters:.*",antsStr,re.M)
  rigidParameters = re.findall(r"\s+(\S+)",rigidLine[0])
  rigidParameters = [float(entry) for entry in rigidParameters]
  # fixed parameters
  centerLine = re.findall(r"^FixedParameters:.*",antsStr,re.M)
  centerParameters = re.findall(r"\s+(\S+)",centerLine[0])
  centerParameters = [float(entry) for entry in centerParameters]
  f_in.close()
  return [rigidParameters, centerParameters]

# function to read a list of parameters and write it into the antsfile
def rigid2ants(rigid,antsFile):
  f_out = open(antsFile,'w')
  rigidParameters = rigid[0]
  rigidParameters = [str(entry) for entry in rigidParameters]
  centerParameters = rigid[1]
  centerParameters = [str(entry) for entry in centerParameters]

  f_out.writelines('#Insight Transform File V1.0\n')
  f_out.writelines('#Transform 0\n')
  f_out.writelines('Transform: MatrixOffsetTransformBase_double_2_2\n')
  f_out.writelines('Parameters: ' + ' '.join(rigidParameters) + '\n')
  f_out.writelines('FixedParameters: ' + ' '.join(centerParameters) + '\n')
  f_out.close()

# Transform the parameters into angle and translation
def rigid2vec(Parameters,center_mean):
  rigidParameters = Parameters[0]
  centerParameters = Parameters[1]
  cosAngle = rigidParameters[0]
  sinAngle = rigidParameters[1]
  angle = math.atan2(sinAngle,cosAngle)
  transX = rigidParameters[4] 
  transY = rigidParameters[5] 
  
  transX_center = ( (1-cosAngle) * (centerParameters[0] - center_mean[0]) - 
                      sinAngle   * (centerParameters[1] - center_mean[1]) ) + transX

  transY_center = ( (1-cosAngle) * (centerParameters[1] - center_mean[1]) + 
                      sinAngle   * (centerParameters[0] - center_mean[0]) ) + transY

  return [angle,transX_center,transY_center]

# Transform the angle and translation into parameters
def vec2rigid(vec,centerParameters):
  [angle,transX,transY] = vec
  rigidParameters = [math.cos(angle),math.sin(angle),math.sin(-angle),math.cos(angle),transX,transY]
  return [rigidParameters,centerParameters]
  
# Calculate the mean value  
def average(value):
  return sum(value) / len(value)
      
# Smooth a sequence of vectors componentwisely with Gaussian parameter sigma
def smoothTransforms(vector,sigma):
  windowSize = int(4.0 * sigma)
  numOfSlices = len(vector)
  numOfComp = len(vector[0])
  vector_smooth = []

  # Perform the blurring
  for iTran in range(numOfSlices):
    xWeightSum = 0.0;
    xSum = [0.0 for i in range(numOfComp)]
    for iOffset in range(-windowSize,windowSize+1):
      # Compute the position of the vector
      iPos = iTran + iOffset
      # Only consider positions inside the range of transforms
      if(iPos >= 0 and iPos < numOfSlices):
        # Compute the Gaussian weight (ignore constants)
        xWeight = math.exp( - iOffset * iOffset / ( sigma * sigma * 2.0 ))

        # Add the transform vector, weighted
        xSum = [xSum[i] + vector[iPos][i] * xWeight for i in range(numOfComp)]
        xWeightSum += xWeight;

    vector_smooth.append([(xSum[i] / xWeightSum) for i in range(numOfComp)])

  return vector_smooth

# the main function
def main(argv=sys.argv):

  if len(sys.argv) != 4:
    print 'Usage: \n' + sys.argv[0] + ' sigma' + ' inputdir' + ' outputdir' + '\n'
    sys.exit(1)

  if argv[2] == argv[3]:
    print 'input directory should be different from output directory'
    sys.exit(1)

  # the smoothing parameter
  sigma = float(argv[1])

  # find all the ants Affine files in the directory
  inputdir = argv[2]
  outputdir = argv[3]

  # Notice here we sort the filenames given by os.listdir
  files = os.listdir(inputdir)
  antsFilesAll = [f for f in files if f.endswith('Affine.txt')]
  antsFilesAll.sort()
  numOfSlices = len(antsFilesAll)

  # create a list to store all the rigid parameters
  rigids = [ants2rigid(os.path.join(inputdir,antsFile)) for antsFile in antsFilesAll]

  # center x and y
  centerX = [rigids[i][1][0] for i in range(0,numOfSlices)]
  centerY = [rigids[i][1][1] for i in range(0,numOfSlices)]

  # mean center x and y 
  center_mean = [average(centerX),average(centerY)]

  # list of vectors each with [angle,transX,transY]
  vector = [rigid2vec(rigids[i],center_mean) for i in range(0,numOfSlices)]

  # smooth the vector with the gaussian filter (with std = sigma)
  vector_smooth = smoothTransforms(vector,sigma)

  for i in range(0,numOfSlices):
    rigid2ants(vec2rigid(vector_smooth[i],center_mean),os.path.join(outputdir,antsFilesAll[i]))
  
if __name__ == "__main__":
  main()
