



/* DEPENDENCIES */
#include "mex.h"
#include "gpu/mxGPUArray.h"



/* FUNCTION PROTOTYPES */
void CalculateTailValues(double* realData, int lenReal, double* nullData, int lenNull, double* pvals)



/* ENTRY POINT */
void mexFunction(int numOutputs, mxArray* pOutputs[], int numInputs, const mxArray* pInputs[])
{

    // Declare variables
    double *realData, *nullData, *pvals;
    int lenReal, lenNull, sumNullComp;
    
    // Initialize input-dependent parameters
    realData = mxGetPr(pInputs[0]);
    nullData = mxGetPr(pInputs[1]);
    lenReal = mxGetN(pInputs[0]);
    lenNull = mxGetN(pInputs[1]);
    
    // Initialize output parameters
    pOutputs[0] = mxCreateDoubleMatrix(2, lenReal, mxREAL);
    pvals = mxGetPr(pOutputs[0]);
    
    // Calculate p-values
    CalculateTailValues(realData, lenReal, nullData, lenNull, pvals);
    
}



/* NESTED FUNCTIONS */
void CalculateTailValues(double* realData, int lenReal, double* nullData, int lenNull, double* pvals)
{
    int a, b;
    for (a = 0; a < lenReal; a++)
    {
        sumNullLower = 0;
        sumNullUpper = 0;
        
        for (b = 0; b < lenNull; b++)
        {
            if (nullData[b] <= realData[a]) { sumNullLower++; } 
            else { sumNullUpper++; }
            
            pvals[2*a] = (double)sumNullLower / (double)lenNull;
            pvals[2*a + 1] = (double)sumNullUpper / (double)lenNull;
        }
    }
}



void CalculateLowerTail(double* realData, int lenReal, double* nullData, int lenNull, double* pvals)
{
    int a, b;
    for (a = 0; a < lenReal; a++)
    {
        sumNullComp = 0;
        for (b = 0; b < lenNull; b++) { if (nullData[b] <= realData[a]) { sumNullComp++; } }
        pvals[(2*a)] = (double)sumNullComp / (double)lenNull;
    }
}

void CalculateUpperTail(double* realData, int lenReal, double* nullData, int lenNull, double* pvals);
{
    int a, b;
    for (a = 0; a < lenReal; a++)
    {
        


/* RESULTS */
// NullData [1 5*length(RealData)]
//
// RealData [1 1000] 
// RealData [1 10000]   --> 1.4219s, 1.4220s