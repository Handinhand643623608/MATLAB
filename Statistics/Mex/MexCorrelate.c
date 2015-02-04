/* MEXCORRELATE - Computes the correlation between an array of signals and one or more additional signals. */

/* CHANGELOG
 * Written by Josh Grooms on 20150203
 */

#include <cilk/cilk.h>
#include <mathimf.h>
#include <mex.h>
#include <mkl.h>



/* PROTOTYPES */
double corr(double x[], double y[], int nsamples);



/* MEX FUNCTION */
void mexFunction(int nargout, mxArray* argout[], int nargin, const mxArray* argin[])
{
	if (nargin != 2)
		mexErrMsgTxt("Two input arguments must be provided to this function. See documentation for syntax details");

	int ncx, ncy, nrx, nry;
	nrx = mxGetM(argin[0]);
	ncx = mxGetN(argin[0]);
	nry = mxGetM(argin[1]);
	ncy = mxGetN(argin[1]);

	if (nrx == 0 || nry == 0) { mexErrMsgTxt("Inputs cannot be empty arrays."); }
	if (nrx != nry) { mexErrMsgTxt("X and Y must contain equivalent length signals."); }
	
	double* x = mxGetPr(argin[0]);
	double* y = mxGetPr(argin[1]);

	argout[0] = mxCreateDoubleMatrix(ncx, ncy, mxREAL);
	double* r = mxGetPr(argout[0]);

	if (ncy == 1)
	{
		cilk_for(int a = 0; a < ncx; a++)
		{
			int idxX = a * nrx;
			r[a] = corr(x + idxX, y, nrx);
		}
	}
	else
	{
		cilk_for(int a = 0; a < ncy; a++)
		{
			int idxY = a * nry;
			int idxR = a * ncx;
			for (int b = 0; b < ncx; b++)
			{
				int idxX = b * nrx;
				r[idxR + b] = corr(x + idxX, y + idxY, nrx);
			}
		}
	}
}



/* SUBROUTINES */
/// <summary>
/// Computes the Pearson product-moment correlation coefficient between two signals.
/// </summary>
/// <param name="x">A signal vector.</param>
/// <param name="y">A second signal vector of the same length as x.</param>
/// <param name="nsamples">The number of sample points in x and y.</param>
/// <returns>The correlation coefficient (r) between x and y.</returns>
double corr(double x[], double y[], int nsamples)
{
	double sx, sy, sxy, ssx, ssy;
	sx = sy = sxy = ssx = ssy = 0;
	for (int a = 0; a < nsamples; a++)
	{
		sx += x[a];
		sy += y[a];
		sxy += x[a] * y[a];
		ssx += x[a] * x[a];
		ssy += y[a] * y[a];
	}

	double cov = (nsamples * sxy) - (sx * sy);
	double scale = sqrt((nsamples * ssx) - (sx * sx)) * sqrt((nsamples * ssy) - (sy * sy));

	return cov / scale;
}