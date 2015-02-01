/* MEXCROSSCORRELATE - Cross-correlates two equivalently sized vectors of data.
 *
 *	SYNTAX:
 *		cc = MexCrossCorrelate(x, y)
 *
 *	OUTPUT:
 *		cc:				[ NCC x NX DOUBLES ]
 *                      The normalized correlation coefficients between the signals in X and Y at every possible sample
 *                      offset. This output will contain a fixed number of rows NCC determined by the number of samples in
 *                      the signals in X and Y: NCC = 2 * M - 1. 
 *
 *	INPUT:
 *		x:				[ M x NX DOUBLES ]
 *                      A column vector or matrix of signals to be cross-correlated with the data in Y. The number of rows in
 *                      this argument should represent the number of samples in the signal(s) being correlated. The number of
 *                      columns NX then represents the number of signals that are present in the data set. This argument
 *                      cannot contain NaNs.
 *
 *		y:				[ M x NY DOUBLES ]
 *                      A column vector or matrix of signals to be cross-correlated with the data in X. Like X, the rows of
 *                      this argument represent individual signal samples, while columns represent the signals themselves.
 *                      The number of samples M in this argument must always equal the number of samples in X. This argument
 *                      also cannot contain NaNs. The number of signals NY must either be 1 or NX.
 */

/* CHANGELOG
 *  Written by Josh Grooms on 20141230
 */

#include <cilk/cilk.h>
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

	if (nrx == 0 || ncx == 0)		{ mexErrMsgTxt("Inputs cannot contain empty arrays."); }

	double* x = mxGetPr(argin[0]);
	double* y = mxGetPr(argin[1]);

	nargout = 1;
	argout[0] = mxCreateDoubleMatrix(ncc, ncx, mxREAL);
	double* cc = mxGetPr(argout[0]);

	if (ncx == 1) { xcorr(cc, x, y, nrx); }
	else if (ncy == 1)
	{
		cilk_for(int a = 0; a < ncx; a++)
		{
            // These indexing declarations MUST be inside the loop to prevent a race condition.
			int idxCC = a * ncc;
			int idxXY = a * nrx;
			xcorr(cc + idxCC, x + idxXY, y, nrx);
		}
	}
	else
	{
		cilk_for(int a = 0; a < ncx; a++)
		{
            // These indexing declarations MUST be inside the loop to prevent a race condition.
			int idxCC = a * ncc;
			int idxXY = a * nrx;
			xcorr(cc + idxCC, x + idxXY, y + idxXY, nrx);
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