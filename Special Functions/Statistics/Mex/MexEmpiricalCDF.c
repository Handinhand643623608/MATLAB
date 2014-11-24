/* MEXEMPIRICALCDF - Generates p-values for data using an empirically derived null distribution.
 *
 *	SYNTAX:
 *		p = MexEmpiricalCDF(r, n)
 *
 *	OUTPUT:
 *		p:		[ N x 1 DOUBLES ]
 *				An array of p-values corresponding with the data in r.
 *
 *	INPUTS:
 *		r:		[ N x 1 DOUBLES ] 
 *				The real data distribution.
 *
 *		n:		[ M x 1 DOUBLES ]
 *				The null data distribution. 
 */

/* CHANGELOG
 * Written by Josh Grooms on 20141121
 */

// DEPENDENCIES
#include <matrix.h>
#include <mex.h>

#include "MexEmpiricalCDF.h"


/// <summary>
///	Serves as the entry point to the MEX function that generates empirical CDFs.
/// </summary>
/// <param name="nargout">The number of arguments that will outputted to MATLAB.</param>
/// <param name="pOut">A pointer to the array of output arguments.</param>
/// <param name="nargin">The number of arguments that are inputted from MATLAB.</param>
/// <param name="pIn">A pointer to the array of input arguments.</param>
void mexFunction(int nargout, mxArray *pOut[], int nargin, const mxArray *pIn[])
{
	double *r, *n, *p;
	int lr, ln;

	r = mxGetPr(pIn[0]);
	n = mxGetPr(pIn[1]);

	lr = mxGetM(pIn[0]);
	ln = mxGetM(pIn[1]);

	nargout = 1;
	*pOut = mxCreateDoubleMatrix(lr, 1, mxREAL);
	p = mxGetPr(pOut[0]);

	double sumNull, pval;
	double invN = 1.0 / ((double)ln);
	for (int a = lr; a--;)
	{
		sumNull = 0.0;
		for (int b = ln; b--;) { if (r[a] >= n[b]) { sumNull++; } }
		pval = sumNull * invN;
		p[a] = 2.0 * min(pval, 1.0 - pval);
	}

}
	
