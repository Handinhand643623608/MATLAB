
/* DEPENDENCIES */
#include <matrix.h>
#include <mex.h>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>

/* CONSTANTS */
#define NumThreads 4



/* MEX ENTRY POINT */
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
	double invN = 1 / ((double)ln);

	__cilkrts_set_param("nworkers", "6");
	#pragma cilk grainsize = 1

	cilk_for (int a = 0; a < lr; a++)
	{
		sumNull = 0;
		for (int b = 0; b < ln; b++) { if (n[a] >= n[b]) { sumNull++; } }
		pval = sumNull * invN;
		p[a] = 2.0 * min(pval, 1.0 - pval);
	}

}