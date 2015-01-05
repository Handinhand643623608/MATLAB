% MEXCROSSCORRELATE  - Cross-correlates two equivalently sized vectors of data.
%
%	SYNTAX:
%		CC = MexCrossCorrelate(X, Y, ScaleOpt)
%
%	OUTPUT:
%		CC:			[ M x 1 DOUBLES ]
%					A column vector of correlation coefficients that together estimate the cross-correlation function 
%					between X and Y. This vector will always be of length (M = 2 * L - 1), meaning it will always 
%					contain correlation estimates for every possible sample shift between the data.
%
%	INPUT:
%		X:			[ L x 1 DOUBLES ]
%					A column vector of data that will be cross-correlated with the data in Y. This vector may be of any 
%					length (L) provided that Y has the same length.
%
%		Y:			[ L x 1 DOUBLES ]
%					A column vector of data that will be cross-correlated with the data in X. This vector may be of any 
%					length (L) provided that X has the same length.
%
%		ScaleOpt:	INTEGER
%					A "magic number" representing the scaling method that will be applied to raw correlation 
%					coefficients. Scaling is useful for comparing correlation coefficient results between analyses on 
%					different data sets, a scenario in which raw correlation values are often of little use.
%					
%					OPTIONS:
%						0: Biased Scaling			- Scales CC coefficients by (1 / ncc).
%						1: Coefficient Scaling		- Scales CC coefficents so that autocorrelations are 1 at 0 lag.
%						2: No Scaling				- Does not scale CC coefficients.
%						3: Unbiased	Scaling			- Scales CC coefficents by (1 / (ncc - abs(lags)))