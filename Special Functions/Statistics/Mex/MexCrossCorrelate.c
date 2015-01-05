/* MEXCROSSCORRELATE - Cross-correlates two equivalently sized vectors of data.
 *
 *	SYNTAX:
 *		CC = MexCrossCorrelate(X, Y, ScaleOpt)
 *
 *	OUTPUT:
 *		CC:			(1 x ncc) [ DOUBLES ]
 *					A column vector of correlation coefficients that together estimate the cross-correlation function 
 *					between X and Y. This vector will always be of length (ncc = 2 * nxy - 1), meaning it will always 
 *					contain correlation estimates for every possible sample shift between the data.
 *
 *	INPUT:
 *		X:			(1 x nxy) [ DOUBLES ]
 *					A column vector of data that will be cross-correlated with the data in Y. This vector may be of any 
 *					length (nxy) provided that Y has the same length.
 *
 *		Y:			(1 x nxy) [ DOUBLES ]
 *					A column vector of data that will be cross-correlated with the data in X. This vector may be of any 
 *					length (nxy) provided that X has the same length.
 *
 *		ScaleOpt:	INTEGER
 *					A "magic number" representing the scaling method that will be applied to raw correlation 
 *					coefficients. Scaling is useful for comparing correlation coefficient results between analyses on 
 *					different data sets, a scenario in which raw correlation values are often of little use.
 *					
 *					OPTIONS:
 *						0: Biased Scaling			- Scales CC coefficients by (1 / ncc).
 *						1: Coefficient Scaling		- Scales CC coefficents so that autocorrelations are 1 at 0 lag.
 *						2: No Scaling				- Does not scale CC coefficients.
 *						3: Unbiased	Scaling			- Scales CC coefficents by (1 / (ncc - abs(lags)))
 */

/* CHANGELOG
 * Written by Josh Grooms on 20141230
 */

#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <mkl.h>
#include <mkl_vsl.h>
#include <stdio.h>

#include "MexCrossCorrelate.h"



/* MEX FUNCTION */
void mexFunction(int nargout, mxArray* argout[], int nargin, const mxArray* argin[])
{
	double *cc, *x, *y;
	int ncc, nx, ny;
	ScaleOpt opt;
	
	if (nargin != 3) 
		mexErrMsgTxt("A minimum of 3 input arguments must be provided to this function. See documentation for syntax details.");

	x = mxGetPr(argin[0]);
	nx = mxGetM(argin[0]);
	y = mxGetPr(argin[1]);
	ny = mxGetM(argin[1]);
	opt = (int)mxGetScalar(argin[2]);

	if (nx != ny) { mexErrMsgTxt("Inputted data vectors X and Y must be of equivalent length."); }

	nargout = 1;
	ncc = 2 * nx - 1;
	*argout = mxCreateDoubleMatrix(ncc, 1, mxREAL);
	cc = mxGetPr(argout[0]);
	
	xcorr(cc, x, y, nx);
	if (opt != None) { scale(cc, x, y, nx, opt); }
}



/* SUBROUTINES */
/// <summary>
///	Applies a scaling option to the raw cross-correlation results. 
/// </summary>
/// <param name="cc">The unscaled correlation coefficients.</param>
/// <param name="x">The x data vector.</param>
/// <param name="y">The y data vector.</param>
/// <param name="nxy">The number of elements in x and y.</param>
/// <param name="opt">One of the supported scaling option enumerators that indicates how to scale the results.</param>
void	scale(double cc[], double x[], double y[], int nxy, ScaleOpt opt)
{
	int ncc = 2 * nxy - 1;
	double scale;

	switch (opt)
	{
		case Biased:
			scale = 1.0 / (double)ncc;
			break;
		case Coeff:
			scale = scalecoeff(cc, x, y, nxy);
			break;		
		case Unbiased:
			mexErrMsgTxt("Sorry, the unbiased scaling option hasn't been implemented yet");
			break;
		default:
			mexErrMsgTxt("Scaling option %d is not recognized. See documentation for acceptable values.", opt);
			return;
	}

	cblas_dscal(ncc, scale, cc, 1);
}
/// <summary>
///	Scales results to Pearson product-moment correlation coefficients.
/// </summary>
/// <param name="cc">The unscaled correlation coefficients.</param>
/// <param name="x">The x data vector.</param>
/// <param name="y">The y data vector.</param>
/// <param name="nxy">The number of elements in x and y.</param>
double	scalecoeff(double cc[], double x[], double y[], const int nxy)
{
	double absx[nxy], absy[nxy], sqx[nxy], sqy[nxy];
	double sumx, sumy;

	vdAbs(nxy, x, absx);
	vdAbs(nxy, y, absy);

	vdSqr(nxy, absx, sqx);
	vdSqr(nxy, absy, sqy);

	sumx = cblas_dasum(nxy, sqx, 1);
	sumy = cblas_dasum(nxy, sqy, 1);

	return 1.0 / sqrt(sumx * sumy);
}
/// <summary>
///	Calculates the cross-correlation function between two vectors X and Y.
/// </summary>
/// <param name="cc">The cross-correlation coefficient storage vector (LENGTH = 2*nxy - 1) that holds the output of this function.</param>
/// <param name="x">A vector of data to be cross-correlated with the data in y.</param>
/// <param name="y">A vector of data to be cross-correlated with the data in X.</param>
/// <param name="nxy">The number of elements in x and y. Both vectors must be of equivalent length.</param>
void	xcorr(double cc[], double x[], double y[], int nxy)
{
	int status;
	VSLCorrTaskPtr task;
	int szdouble = sizeof(double);

	int ncc = 2 * nxy - 1;
	status = vsldCorrNewTask1D(&task, VSL_CORR_MODE_FFT, nxy, nxy, ncc);
	if (status != 0) { printf("Could not initialize the correlation task. Error code: %d\n", status); }

	// X & Y are swapped here because VSL outputs coefficients in a reversed order relative to MATLAB's convention. 
	// Since we are requiring X and Y to have the same sizes, this swap conveniently makes everything consistent again. 
	status = vsldCorrExec1D(task, y, 1, x, 1, cc, 1);
	if (status != 0) { printf("Could not run the correlation task. Error code: %d\n", status); }

	status = vslCorrDeleteTask(&task);
	if (status != 0) { printf("Could not delete the correlation task. Error code %d\n", status); }
}



