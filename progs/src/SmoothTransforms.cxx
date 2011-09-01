/**
 * Program: smooth_transforms
 * Purpose: smooths a bunch of transforms taking histology images 
 *          into MRI slices
 * Author:  Paul Yushkevich
 */

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <math.h>
#include <vnl/vnl_vector_fixed.h>
#include <vnl/vnl_qr.h>

using namespace std;

int usage()
{
  const char *sUsage = 
    "-------------------\n"
    " smooth_transforms\n"
    "-------------------\n"
    "Takes a list of transforms and smooths them, using a Gaussian kernel. This\n"
    "program is used to ensure the consistency of the histo-to-mri transforms.\n"
    "\n"
    "  usage: smooth_transforms [options] src_dir target_dir files...\n"
    "\n"
    "  options:\n"
    "        \n"
    "    -s, --sigma <x>           The standard deviation of the smoothing kernel.\n"
    "                              Default: 4.0\n"
    "                                          \n"
    "Input files must not include a path\n"
    "Each input file will be smoothed and placed in the directory target_dir\n";

  cout << sUsage << endl;
  return -1;
}

int main(int argc, char *argv[])
{
  // Check number of arguments
  if(argc < 3) return usage();

  // These are the arguments we will need
  string sTargetPath, sSourcePath;
  vector<string> asFiles;
  double xSigma;

  // Read the arguments
  try 
    {
    for(unsigned int iArg=1;iArg < argc; iArg++)
      {
      string sArg(argv[iArg]);
      if(sArg == "-s" || sArg == "--sigma")
        {
        xSigma = atof(argv[++iArg]);
        }
      else if(sSourcePath.length() == 0)
        {
        sSourcePath = sArg;
        }
      else if(sTargetPath.length() == 0)
        {
        sTargetPath = sArg;
        }
      else
        {
        asFiles.push_back(sArg);
        }
      } 
    }
  catch(...) 
    {
    cerr << "Error parsing command line parameters!" << endl;
    return usage();
    }

  // Make sure parameters are OK
  if(sSourcePath == "")
    {
    cerr << "No source path specified!" << endl;
    return usage();
    }
  else if(sTargetPath == "")
    {
    cerr << "No target path specified!" << endl;
    return usage();
    }
  else if(sTargetPath == sSourcePath)
    {
    cerr << "Source and target paths can not be the same!" << endl;
    return usage();
    }
  else if(asFiles.size() < 2)
    {
    cerr << "Must have at least two transforms to smooth!" << endl;
    return usage();
    }

  // Read the transform parameters from the input files.  For the time
  // being we are dealing with rigid transforms, so we will apply smoothing
  // directly to the angles and offsets. Later, for affine transforms we will
  // need something more sophisticated

  // typedef vnl_vector_fixed<double, 3> ParmVector;
  // vector<ParmVector> aTransforms;

  unsigned int iTran, nTran = asFiles.size();
  double **aTransforms = new double*[nTran];
  for (int i = 0; i < nTran; i++) { aTransforms[i] = new double[3]; }

  for(iTran = 0; iTran < nTran; iTran++)
    {
    try 
      {
      // Open file for reading
      string sInputFile = sSourcePath + "/" + asFiles[iTran];
      ifstream fin(sInputFile.c_str(),ios_base::in);
      if(!fin.good()) 
        throw "Can't read file!";

      // Read the three numbers
      // ParmVector xParm(0.0);
      char buffer[256];
      for(unsigned int j=0;j<3;j++)
        {
        fin.getline(buffer,256);
        // xParm[j] = atof(buffer);
        aTransforms[iTran][j] = atof(buffer);
        }
      fin.close();

      // Add to the array
      // aTransforms.push_back(xParm);
      }
    catch(...)
      {
      cerr << "Error reading file " << asFiles[iTran] << endl;
      return usage();
      }
    }

  // Compute the window size
  int xWindow = (int) (xSigma * 4.0);

  // Perform the blurring
  for(iTran = 0; iTran < nTran; iTran++)
    {
    double xWeightSum = 0.0;
    //ParmVector xSum(0.0);
    double xSum[] = {0.0, 0.0, 0.0};

    for(int iOffset = -xWindow; iOffset <= xWindow; iOffset++)
      {
      // Compute the position of the vector
      int iPos = iTran + iOffset;

      // Only consider positions inside the range of transforms
      if(iPos >= 0 && iPos < nTran)
        {
        // Compute the Gaussian weight (ignore constants)
        double xWeight = exp( - iOffset * iOffset / ( xSigma * xSigma * 2.0 ));

        // Add the transform vector, weighted
        //xSum += aTransforms[iPos] * xWeight;
        for (int i = 0; i < 3; i++) { xSum[i] += aTransforms[iPos][i] * xWeight; }
        xWeightSum += xWeight;
        }
      }

    // Divide by the total weight
    // xSum *= (1.0 / xWeightSum);
    for (int i = 0; i < 3; i++) { xSum[i] *= 1.0 / xWeightSum; }

    cout << "(" << aTransforms[iTran][0] << ", " << aTransforms[iTran][1] << ", " << aTransforms[iTran][2] << ") ==> (" << xSum[0] << ", " << xSum[1] << ", " << xSum[2] << ")" << endl;

    // Save the blurred transform vector and matrix
    string sOutFile = sTargetPath + "/" + asFiles[iTran];
    try
      {
      ofstream fout(sOutFile.c_str(), ios_base::out);
      if(!fout.good())
        throw "Can't write file";

      fout << xSum[0] << endl;
      fout << xSum[1] << endl;
      fout << xSum[2] << endl;
      fout.close();
      }
    catch(...)
      {
      cerr << "Error writing results to sOutFile" << endl;
      return usage();
      }
    }

  for (int i = 0; i < nTran; i++) { delete[] aTransforms[i]; }
  delete[] aTransforms;

  return 0;
}



