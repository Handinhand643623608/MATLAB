/* ARRAYPRODUCT - Calculates the element-wise product of a scalar and a vector in C.
 *  This function is essentially a learning exercise for getting familiar with the C language MATLAB interface (i.e. MEX 
 *  files). Although this function executes quickly, it has no realistic applications and is definitely slower than the 
 *  native multiplication.
 */

/* CHANGELOG
 * Written by Josh Grooms on 20140708
 */

#include "mex.h"


void ArrayProduct(double x, double* y, double* z, int n)
{
    mwSize a;
    for (a = 0; a < n; a++) { z[a] = x * y[a]; }
}



// Gateway function
void mexFunction(int numOutputs, mxArray* pOutputs[], int numInputs, const mxArray* pInputs[])
{
    // Variable declarations
    mwSize numColumns;
    double x;
    double* y;
    double* z;
    
    // Input/output parameter validation
    if (numInputs != 2) { mexErrMsgIdAndTxt("MyToolbox:arrayProduct:NumInputs", "Two inputs are required."); }
    if (numOutputs != 1) { mexErrMsgIdAndTxt("MyToolbox:arrayProduct:NumOutputs", "One output is required"); }
    if (!mxIsDouble(pInputs[1]) || mxIsComplex(pInputs[1])) { mexErrMsgIdAndTxt("MyToolbox:arrayProduct:NotDouble", "Input matrix must be of type double"); }
    if (mxGetM(pInputs[1]) != 1) { mexErrMsgIdAndTxt("MyToolbox:arrayProduct:NotRowVector", "Input matrix must be a row vector"); }
    if (!mxIsDouble(pInputs[0]) || mxIsComplex(pInputs[0]) || mxGetNumberOfElements(pInputs[0]) != 1)
    {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar", "Input multiplier must be a scalar");
    }
    
    // Fill in variables declared earlier
    numColumns = mxGetN(pInputs[1]);
    x = mxGetScalar(pInputs[0]);
    y = mxGetPr(pInputs[1]);
    pOutputs[0] = mxCreateDoubleMatrix(1, numColumns, mxREAL);
    z = mxGetPr(pOutputs[0]);
    
    // Calculate the array product
    ArrayProduct(x, y, z, numColumns);
}


