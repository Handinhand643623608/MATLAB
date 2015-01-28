/* MEXCROSSCORRELATE - Cross-correlates two equivalently sized vectors of data.
*
*	SYNTAX:
*		CC = MexCrossCorrelate(X, Y)
*
*	OUTPUT:
*		CC:			[ NCC x 1 DOUBLES ]
*					A column vector of correlation coefficients that together estimate the cross-correlation function
*					between X and Y. This vector will always be of length (ncc = 2 * nxy - 1), meaning it will always
*					contain correlation estimates for every possible sample shift between the data.
*
*	INPUT:
*		X:			[ M x N DOUBLES ]
*					A column vector of data that will be cross-correlated with the data in Y. This vector may be of any
*					length (nxy) provided that Y has the same length.
*
*		Y:			[ M x N DOUBLES ]
*					A column vector of data that will be cross-correlated with the data in X. This vector may be of any
*					length (nxy) provided that X has the same length.
*/

/* CHANGELOG
* Written by Josh Grooms on 20141230
*/

#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <mkl.h>



/* MACROS */
void	_check(int status, int line)
{
	if (status != 0) { printf("Something went wrong at line %d", line); }
}

#define check(status) _check(status, __LINE__)



/* FUNCTION PROTOTYPES */
void	xcorr(double cc[], double x[], double y[], int nsamples);



/* MEX FUNCTION */
void mexFunction(int nargout, mxArray* argout[], int nargin, const mxArray* argin[])
{
	if (nargin != 2)
		mexErrMsgTxt("Two input arguments must be provided to this function. See documentation for syntax details.");

	int ncc, ncx, nrx, ncy, nry;
	nrx = mxGetM(argin[0]);
	ncx = mxGetN(argin[0]);
	nry = mxGetM(argin[1]);
	ncy = mxGetN(argin[1]);
	ncc = 2 * nrx - 1;

	if (nrx != nry || ncx != ncy)	{ mexErrMsgTxt("Inputted data arrays X and Y must be of equivalent size."); }
	if (nrx == 0 || ncx == 0)		{ mexErrMsgTxt("Inputs cannot contain empty arrays."); }

	double* x = mxGetPr(argin[0]);
	double* y = mxGetPr(argin[1]);

	nargout = 1;
	argout[0] = mxCreateDoubleMatrix(ncc, ncx, mxREAL);
	double* cc = mxGetPr(argout[0]);

	if (ncx == 1) { xcorr(cc, x, y, nrx); }
	else
	{
		int idxCC = 0;
		int numelCC = nrx * ncx;
		for (int a = 0; a <= numelCC - nrx; a += nrx)
		{
			xcorr(cc + idxCC, x + a, y + a, nrx);
			idxCC += ncc;
		}
	}	
}



/* SUBROUTINES */
/// <summary>
///	Calculates the cross-correlation function between two vectors X and Y.
/// </summary>
/// <param name="cc">The cross-correlation coefficient storage vector (LENGTH = 2*nxy - 1) that holds the output of this function.</param>
/// <param name="x">A vector of data to be cross-correlated with the data in y.</param>
/// <param name="y">A vector of data to be cross-correlated with the data in X.</param>
/// <param name="nxy">The number of elements in x and y. Both vectors must be of equivalent length.</param>
void	xcorr(double cc[], double x[], double y[], int nsamples)
{
	int status;
	VSLCorrTaskPtr task;
	int ncc = 2 * nsamples - 1;
	int szdouble = sizeof(double);

	status = vsldCorrNewTask1D(&task, VSL_CORR_MODE_FFT, nsamples, nsamples, ncc);
	check(status);

	// X & Y are swapped here because VSL outputs coefficients in a reversed order relative to MATLAB's convention. 
	// Since we are requiring X and Y to have the same sizes, this swap conveniently makes everything consistent again. 
	status = vsldCorrExec1D(task, y, 1, x, 1, cc, 1);
	check(status);

	status = vslCorrDeleteTask(&task);
	check(status);

	// Scale the results to Pearson product-moment correlation coefficients
	double sumx, sumy;
	double absx[nsamples], absy[nsamples], sqx[nsamples], sqy[nsamples];

	vdAbs(nsamples, x, absx);
	vdAbs(nsamples, y, absy);

	vdSqr(nsamples, absx, sqx);
	vdSqr(nsamples, absy, sqy);

	sumx = cblas_dasum(nsamples, sqx, 1);
	sumy = cblas_dasum(nsamples, sqy, 1);

	cblas_dscal(ncc, 1.0 / sqrt(sumx * sumy), cc, 1);
}