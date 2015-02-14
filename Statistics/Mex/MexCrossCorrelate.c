/* MEXCROSSCORRELATE - Cross-correlates two equivalently sized vectors of data. */

/* CHANGELOG
 * Written by Josh Grooms on 20141230
 *		20150210:	Updated to remove the restrictions on the number of columns in X and Y. These can now freely vary. 
 *					Updated the documentation of this function to reflect this change and to improve clarity.
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

	double* x = mxGetPr(argin[0]);
	double* y = mxGetPr(argin[1]);

	int ncc, ncx, nrx, ncy, nry;
	nrx = mxGetM(argin[0]);
	ncx = mxGetN(argin[0]);
	nry = mxGetM(argin[1]);
	ncy = mxGetN(argin[1]);
	ncc = 2 * nrx - 1;

	if (nrx == 0 || ncx == 0)		{ mexErrMsgTxt("Inputs cannot be empty arrays."); }
	if (nrx != nry)					{ mexErrMsgTxt("X and Y must contain equivalent length signals."); }

	argout[0] = mxCreateDoubleMatrix(ncc, ncx * ncy, mxREAL);
	double* cc = mxGetPr(argout[0]);

	if (ncx == 1) { xcorr(cc, x, y, nrx); }
	else if (ncy == 1)
	{
		cilk_for (int a = 0; a < ncx; a++)
		{
			int idxCC = a * ncc;
			int idxColX = a * nrx;
			xcorr(cc + idxCC, x + idxColX, y, nrx);
		}
	}
	else
	{
		cilk_for (int a = 0; a < ncy; a++)
		{
			int idxColY = a * nry;
			for (int b = 0; b < ncx; b++)
			{
				int idxCC = ncc * (a * ncx + b);
				int idxColX = b * nrx;
				xcorr(cc + idxCC, x + idxColX, y + idxColY, nrx);
			}
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