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



#ifndef MexCrossCorrelateHeader
	#define MexCrossCorrelateHeader
	
	
	/* DATA PROTOTYPES */
	typedef enum
	{
		/// <summary>
		///	Scale by the number of coefficients generated (ncc = 2*nxy - 1).
		/// </summary>
		Biased = 0,
		/// <summary>
		///	Scale to Pearson product-moment correlation coefficients (r).
		/// </summary>
		Coeff,
		/// <summary>
		/// Do not scale correlation coefficients.
		/// </summary>
		None,
		/// <summary>
		/// Not implemented yet.
		/// </summary>
		Unbiased,
	/// <summary>
	///	A list of supported correlation coefficient scaling options.
	/// </summary>
	}ScaleOpt;


	
	/* FUNCTION PROTOTYPES */
	/// <summary>
	///	Applies a scaling option to the raw cross-correlation results. 
	/// </summary>
	/// <param name="cc">The unscaled correlation coefficients.</param>
	/// <param name="x">The x data vector.</param>
	/// <param name="y">The y data vector.</param>
	/// <param name="nxy">The number of elements in x and y.</param>
	/// <param name="opt">One of the supported scaling option enumerators that indicates how to scale the results.</param>
	void	scale(double cc[], double x[], double y[], int nxy, ScaleOpt opt);
	/// <summary>
	///	Scales results to Pearson product-moment correlation coefficients.
	/// </summary>
	/// <param name="cc">The unscaled correlation coefficients.</param>
	/// <param name="x">The x data vector.</param>
	/// <param name="y">The y data vector.</param>
	/// <param name="nxy">The number of elements in x and y.</param>
	double	scalecoeff(double cc[], double x[], double y[], const int nxy);
	/// <summary>
	///	Calculates the cross-correlation function between two vectors X and Y.
	/// </summary>
	/// <param name="cc">The cross-correlation coefficient storage vector (LENGTH = 2*nxy - 1) that holds the output of this function.</param>
	/// <param name="x">A vector of data to be cross-correlated with the data in y.</param>
	/// <param name="y">A vector of data to be cross-correlated with the data in X.</param>
	/// <param name="nxy">The number of elements in x and y. Both vectors must be of equivalent length.</param>
	void	xcorr(double cc[], double x[], double y[], int nxy);
	
	
#endif