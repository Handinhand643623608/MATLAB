% CCORR - Estimates the cross-correlation function between data sets.
%
%	CCORR computes the cross-correlation between data just like the MATLAB-native statistical function XCORR does,
%	returning identical results. However, this function offers much better performance than the native function does by
%	wrapping a compiled C MEX function that was created using the Intel C++ Optimizing Compiler (from the Composer XE
%	2015 suite). Consequently, this function is always faster than XCORR, especially at large sample sizes (more than 2x
%	faster at 1,000,000 samples). 
%
%	IMPORTANT WARNINGS:
%		- This code is still in development and isn't nearly as functional as XCORR is.
%		- CCORR currently only works on two signal vectors, although support for arrays is planned.
%		- Inputted signals MUST currently be of equivalent length, although support for size differences is planned.
%		- The scaling option Unbiased is currently not implemented. Attempting to use it will result in an error.
%
%	EXTREMELY IMPORTANT:
%		- The path to the Intel MKL libraries (.dll, not .lib) must currently be on the system's PATH environment
%		  variable. This really sucks, I know, but for reasons that aren't clear to me I couldn't get the MEX function
%		  to compile any other way, and it's potentially illegal for me to redistribute the MKL DLLs anyway. If you
%		  don't have the MKL libraries, this function cannot be used at all. 
%
%	SYNTAX:
%		cc = ccorr(x, y)
%		cc = ccorr(x, y, scaleOpt)
%		[cc, lags] = ccorr(...)
%
%	OUTPUTS:
%		cc:				[ M x 1 DOUBLES ]
%
%		lags:			[ M x 1 INTEGERS ]
%
%	INPUTS:
%		x:				[ L x 1 DOUBLES ]
%
%		y:				[ L x 1 DOUBLES ]
%
%		scaleOpt:		STRING
%						A string indicating how the results in CC should be scaled before returning. These are the same
%						scaling options that can be used with the MATLAB-native XCORR function. However, instead of no
%						scaling, which is the default for XCORR, the results from this function are normalized to
%						Pearson product-moment correlation coefficients.
%
%						DEFAULT: 'coeff'
%						OPTIONS:
%							'biased'	- Scales CC by (1 / M).
%							'coeff'		- Scales CC such that autocorrelations are 1 at zero lag.
%							'none'		- Does not scale CC.
%							'unbiased'	- Scales CC by (1 / (M - abs(lags))). [ NOT IMPLEMENTED YET! ]
%	
%
%	See also: CORR2, CORR3, CORRCOEF, XCORR, XCORRARR

%% CHANGELOG
%	Written by Josh Grooms on 20150105

%% TODOS
%	- Implement the biased scaling option
%	- Implement support for cross-correlating arrays
%	- Finish documenting this function



function [cc, lags] = ccorr(x, y, scaleOpt)

	% Deal with missing inputs
	if nargin == 1; scaleOpt = 'coeff'; end	
	
	% Error checking
	assert(isvector(x) && isvector(y),...
		'This function currently only works for data vectors (i.e. signals). Array support will be implemented later.');
	assert(length(x) == length(y),...
		'Signals must currently be of equivalent length. Differences in signal length will be supported later.');
	
	% Convert data to column vectors if necessary
	x = x(:);
	y = y(:);
	
	% Computs the vector of sample lags
	maxLag = length(x) - 1;
	lags = -maxLag : maxLag;

	% Convert the coefficient scaling option to work with the MEX function
	switch lower(scaleOpt)
		case 'biased'
			opt = 0;
		case 'coeff'
			opt = 1;
		case 'none'
			opt = 2;
		case 'unbiased'
			error('The ''Unbiased'' scaling option is not yet implemented. Sorry!.');
% 			opt = 3;
		otherwise
			error('Unrecognized scaling option %s. See this function''s documentation for supported values.', scaleOpt);
	end
			
	
	% Estimate cross-correlation using the MEX function
	cc = MexCrossCorrelate(x, y, opt);
	
end