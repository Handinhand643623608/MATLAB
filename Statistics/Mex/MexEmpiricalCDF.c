/* MEXEMPIRICALCDF - Generates p-values for data using an empirically derived null distribution.
 *
 *	SYNTAX:
 *		p = MexEmpiricalCDF(r, n)
 *
 *	OUTPUT:
 *		p:		[ N x 1 DOUBLES ]
 *				An array of p-values corresponding with the data in r. This will always be a column vector of
 *				double-precision numbers that is the same length as r (length L). Each p-value in this vector is
 *				associated with the corresponding value in r.
 *
 *	INPUTS:
 *		r:		[ N x 1 DOUBLES ] 
 *				The real data distribution. This should be the data that will be tested for statistical significance
 *				after conversion to p-values. This must be a column vector of double-precision numbers of length L.
 *				
 *				WARNING:
 *					- NaNs or zeros in this vector must be removed prior to invoking this function.
 *
 *		n:		[ M x 1 DOUBLES ]
 *				The null data distribution. This should be an empirically derived null data distribution, which is an
 *				estimate of what the data in R would look like if the null hypothesis that is to be tested is in fact
 *				true. Like R, this must be a column vector of double-precision numbers, but the lengths of R and N do
 *				not necessarily have to agree.
 *	
 *				WARNINGS:
 *					- NaNs or zeros in this vector must be removed prior to invoking this function.
 *					- This vector MUST be sorted into ascending order before calling this function.
 */

/* CHANGELOG
 *	Written by Josh Grooms on 20141121
 *		20150205:	Rewrote the p-value generation to rely on null distributions being sorted, which should be faster. 
 *					Updated the documentation accordingly. Also parallelized this function to improve performance.
 */

#include <cilk\cilk.h>
#include <matrix.h>
#include <mex.h>



/// <summary>
///	Serves as the entry point to the MEX function that generates empirical CDFs.
/// </summary>
/// <param name="nargout">The number of arguments that will outputted to MATLAB.</param>
/// <param name="pOut">A pointer to the array of output arguments.</param>
/// <param name="nargin">The number of arguments that are inputted from MATLAB.</param>
/// <param name="pIn">A pointer to the array of input arguments.</param>
void mexFunction(int nargout, mxArray* argout[], int nargin, const mxArray* argin[])
{
	double *r, *n, *p;
	int lr, ln;

	r = mxGetPr(argin[0]);
	n = mxGetPr(argin[1]);

	lr = mxGetM(argin[0]);
	ln = mxGetM(argin[1]);

	argout[0] = mxCreateDoubleMatrix(lr, 1, mxREAL);
	p = mxGetPr(argout[0]);

	double sumNull, pval;
	double invN = 1.0 / ((double)ln);

	int a = 0;
	cilk_for (int a = 0; a < lr; a++)
	{
		int b = 0;
		while (n[b] < r[a] && b < ln) { b++; }
		double pval = (double)b * invN;
		p[a] = 2.0 * min(pval, 1.0 - pval);
	}
}
	
