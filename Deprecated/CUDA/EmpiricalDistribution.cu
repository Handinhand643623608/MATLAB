/* EMPIRICALDISTRIBUTION - */

/* CHANGELOG
 * Written by Josh Grooms on 20140903
 */

/* TODOS
 * - Dynamically calculate the number of blocks/threads to call the kernel with
 * - Implement (optional?) conversion of double arrays to float arrays (better for GeForce GPUs)
 */

/* DEPENDENCIES */
#include "mex.h"
#include "gpu/mxGPUArray.h"



/* MACROS */
#define Error(id, txt) mexErrMsgIdAndTxt(id, txt);



/* FUNCTION PROTOTYPES */
__global__ void CalculateTailValues(const double *realData, const double *nullData, const int lenNull, double* pvals);



/* MEX ENTRY POINT */
void mexFunction(const int numOutputs, mxArray *pOutputs[], const int numInputs, const mxArray* pInputs[])
{

    // Declare variables
    mxGPUArray* pvalsGPU;
    
    // Error check
    if (numInputs != 2) { Error("EmpiricalDistribution:NumInputs", "Two inputs must be provided to this function."); }
    if (numOutputs != 1) { Error("EmpiricalDistribution:NumOutputs", "Only one output may be requested from this function."); }
    
    // Initialize the GPU API
    mxInitGPU();
    
    // Get the real & null data sets that were inputted
    const mxArray *realDataCPU = (mxArray *)mxGetPr(pInputs[0]);
    const mxArray *nullDataCPU = (mxArray *)mxGetPr(pInputs[1]);
    const int lenReal = mxGetN(pInputs[0]);
    const int lenNull = mxGetN(pInputs[1]);
    
    // Make read-only copies of inputted data sets on the GPU
    const mxGPUArray *realDataGPU = mxGPUCreateFromMxArray(realDataCPU);
    const mxGPUArray *nullDataGPU = mxGPUCreateFromMxArray(nullDataCPU);
    
    // Initialize the p-value output array on the GPU
    mwSize szPVals[] = { 2, lenReal };
    pvalsGPU = mxGPUCreateGPUArray(2, szPVals, mxGPUGetClassID(realDataGPU), mxREAL, MX_GPU_DO_NOT_INITIALIZE);
    
    // Call the CUDA kernel
    CalculateTailValues<<<1, 1000>>>((double *)realDataGPU, (double *)nullDataGPU, lenNull, (double *)pvalsGPU);
    
    // Transfer GPU p-value array back to the host
    pOutputs[0] = mxGPUCreateMxArrayOnCPU(pvalsGPU);
    
    // Clear data off of the GPU
    mxGPUDestroyGPUArray(realDataGPU);
    mxGPUDestroyGPUArray(nullDataGPU);
    mxGPUDestroyGPUArray(pvalsGPU);
}



/* NESTED FUNCTIONS */
__global__ void CalculateTailValues(const double *realData, const double *nullData, const int lenNull, double *pvals)
{
    int a;
    const int i = threadIdx.x;
    int sumNullLower = 0;
    
    for (a = 0; a < lenNull; a++) { if (nullData[a] <= realData[i]) { sumNullLower++; } }
    
    pvals[2*i] = (double)sumNullLower / (double)lenNull;
}