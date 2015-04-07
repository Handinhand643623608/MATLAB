/* CGENERATION - Generates the lower
 *
 */

/* CHANGELOG
 * Written by Josh Grooms on 20141114
 */

/* DEPENDENCIES */
#include "matrix.h"
#include "mex.h"


void mexFunction(int numOutputs, mxArray *pOutputs[], int numInputs, const mxArray *pInputs[])
{
	
	double *realData, *nullData, *pvals;
	double sumNull;
	int lenReal, lenNull;
	
	realData = mxGetPr(pInputs[0]);
	nullData = mxGetPr(pInputs[1]);
	
	lenReal = mxGetM(pInputs[0]);
	lenNull = mxGetM(pInputs[1]);
	
	*pOutputs = mxCreateDoubleMatrix(1, lenReal, mxREAL);
	pvals = mxGetPr(pOutputs[0]);
	numOutputs = 1;
	
	double pvalScale = 1 / ((double)lenNull);
	for (int a = lenReal; a--; )
	{
		sumNull = 0;
		
		for (int b = lenNull; b--; )
		{
			if (realData[a] >= nullData[b]) { sumNull++; }
		}
		
		pvals[a] = sumNull * pvalScale;
	}
}