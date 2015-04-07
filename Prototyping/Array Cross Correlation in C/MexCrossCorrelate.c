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



/* MACROS */
void	_check(int status, int line)
{
	if (status != 0) { printf("Something went wrong at line %d", line); }
}

#define check(status) _check(status, __LINE__)
/// <summary>
/// Calculates the exponent used to find the next power of two greater than the inputted number.
/// <para> </para>
/// This function calculates the first exponent y such that pow(2, y) >= x. 
/// </summary>
/// <param name="x">Any numeric type number.</param>
/// <returns>The first integer exponent such that two raised to it is greater than x.</returns>
#define nextexp2(x) (int)ceil(log2(x))
/// <summary>
///	Calculates the next power of two that is greater than the inputted number.
/// <para> </para>
/// This function calculates a number that is higher than the input x and can be <para/>
/// expressed as pow(2, y), where y some other integer. Specifically, it returns z such <para/>
/// that z = pow(2, y) >= x. For example, the next higher power of two of 3 is 4, and <para/>
/// the next higher power of 17 is 32.
/// </summary>
/// <param name="x">Any numeric type number.</param>
/// <returns>The first integer power of two that is greater than x.</returns>
#define nextpow2(x) (int)pow(2, nextexp2(x))



/* FUNCTION PROTOTYPES */
void	axcorr(double cc[], double x[], double y[], int nfft, int nsamples, int nsignals);
void	scale(double cc[], double x[], double y[], int nxy);
void	xcorr(double cc[], double x[], double y[], int nsamples);
void	zeropad(double xp[], double x[], int psamples, int nsamples, int nsignals);



/* MEX FUNCTION */
void mexFunction(int nargout, mxArray* argout[], int nargin, const mxArray* argin[])
{
	if (nargin != 2)
		mexErrMsgTxt("A minimum of 2 input arguments must be provided to this function. See documentation for syntax details.");

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
		int nfft = nextpow2(ncc);
		int numelPadded = nfft * ncx;

		double xp[numelPadded], yp[numelPadded];
		//double* xp = (double*)mxCalloc(numelPadded, sizeof(double));
		//double* yp = (double*)mxCalloc(numelPadded, sizeof(double));

		zeropad(xp, x, nfft, nrx, ncx);
		zeropad(yp, y, nfft, nry, ncy);

		axcorr(cc, xp, yp, nfft, nrx, ncx);

		int idxCC = 0;
		int numelCC = nrx * ncx;
		for (int a = 0; a <= numelCC - nrx; a += nrx)
		{
			scale(cc + idxCC, x + a, y + a, nrx);
			idxCC += ncc;
		}

		//mxFree(xp);
		//mxFree(yp);

		//int idxCC = 0;
		//int numelCC = nrx * ncx;
		//for (int a = 0; a <= numelCC - nrx; a += nrx)
		//{
		//	xcorr(cc + idxCC, x + a, y + a, nrx);
		//	if (opt != None) { scale(cc + idxCC, x + a, y + a, nrx, opt); }
		//	idxCC += ncc;
		//}

	}

	
}



/* SUBROUTINES */

void	axcorr(double cc[], double x[], double y[], int nfft, int nsamples, int nsignals)
{
	int status;
	int ncc = 2 * nsamples - 1;
	int nel = nsamples * nsignals;
	int nelp = nfft * nsignals;

	MKL_Complex16 Fx[nelp], Fy[nelp], Cxy[nelp];
	double ccp[nelp];
	//MKL_Complex16 *Fx, *Fy, *Cxy;
	//double* ccp;

	//Fx = (MKL_Complex16*)mxCalloc(nelp, sizeof(MKL_Complex16));
	//Fy = (MKL_Complex16*)mxCalloc(nelp, sizeof(MKL_Complex16));
	//Cxy = (MKL_Complex16*)mxCalloc(nelp, sizeof(MKL_Complex16));
	//ccp = (double*)mxCalloc(nelp, sizeof(double));


	DFTI_DESCRIPTOR_HANDLE desc;
	status = DftiCreateDescriptor(&desc, DFTI_DOUBLE, DFTI_REAL, 1, nfft);			check(status);

	status = DftiSetValue(desc, DFTI_PLACEMENT, DFTI_NOT_INPLACE);					check(status);
	status = DftiSetValue(desc, DFTI_CONJUGATE_EVEN_STORAGE, DFTI_COMPLEX_COMPLEX);	check(status);
	status = DftiSetValue(desc, DFTI_NUMBER_OF_TRANSFORMS, nsignals);				check(status);
	status = DftiSetValue(desc, DFTI_INPUT_DISTANCE, nfft);							check(status);
	status = DftiSetValue(desc, DFTI_OUTPUT_DISTANCE, nfft);						check(status);
	status = DftiSetValue(desc, DFTI_BACKWARD_SCALE, 1.0 / (double)nfft);			check(status);
	status = DftiCommitDescriptor(desc);											check(status);

	status = DftiComputeForward(desc, x, Fx);										check(status);
	status = DftiComputeForward(desc, y, Fy);										check(status);

	vzMulByConj(nelp, Fx, Fy, Cxy);

	status = DftiComputeBackward(desc, Cxy, ccp);									check(status);
	status = DftiFreeDescriptor(&desc);												check(status);

	// Rearrange cross-correlation values
	int idxccp;
	int idxcc = 0;
	int bstart = nfft - nsamples + 1;
	for (int a = 0; a < nsignals; a++)
	{
		idxccp = a * nfft;
		for (int b = bstart; b < nfft; b++)
		{
			cc[idxcc++] = ccp[idxccp + b];
		}

		for (int b = 0; b < nsamples; b++)
		{
			cc[idxcc++] = ccp[idxccp + b];
		}
	}

	//mxFree(Fx);
	//mxFree(Fy);
	//mxFree(Cxy);
	//mxFree(ccp);
}
/// <summary>
///	Applies a scaling option to the raw cross-correlation results. 
/// </summary>
/// <param name="cc">The unscaled correlation coefficients.</param>
/// <param name="x">The x data vector.</param>
/// <param name="y">The y data vector.</param>
/// <param name="nxy">The number of elements in x and y.</param>
/// <param name="opt">One of the supported scaling option enumerators that indicates how to scale the results.</param>
void	scale(double cc[], double x[], double y[], int nxy)
{
	double scale;
	int ncc = 2 * nxy - 1;
	double absx[nxy], absy[nxy], sqx[nxy], sqy[nxy];
	double sumx, sumy;

	vdAbs(nxy, x, absx);
	vdAbs(nxy, y, absy);

	vdSqr(nxy, absx, sqx);
	vdSqr(nxy, absy, sqy);

	sumx = cblas_dasum(nxy, sqx, 1);
	sumy = cblas_dasum(nxy, sqy, 1);

	cblas_dscal(ncc, 1.0 / sqrt(sumx * sumy), cc, 1);
}
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
}

void	zeropad(double xp[], double x[], int nrxp, int nrx, int ncx)
{
	int idx, idxp;
	int multiplier = 0;

	for (int a = 0; a < ncx; a++)
	{
		for (int b = 0; b < nrxp; b++)
		{
			idxp = nrxp * a + b;
			xp[idxp] = (b < nrx) ? x[nrx * a + b] : 0;
		}
	}
}


