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
%		x:				[ DOUBLES ]
%
%		y:				[ DOUBLES ]
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
%	Written by Josh Grooms on 20150106

%% TODOS
%	- Implement the biased scaling option
%	- Finish documenting this function
%	- Find a way to test for MKL library presence



%% Function Definition
function [cc, lags] = ccorr(x, y, dim, scaleOpt, funOpt)

	% Deal with missing inputs
	if nargin < 2;		y = x;				end
	if isempty(y);		y = x;				end
	if nargin < 3;		dim = 1;			end
	if nargin < 4;		scaleOpt = 'coeff';	end
	
	% Check for errors in inputs
	hasNaN = any(isnan(x(:))) || any(isnan(y(:)));
	assert(~isempty(x), 'X cannot be an empty array.');
	assert(~hasNaN, 'NaNs were detected in one or more inputted data sets. These must be removed or replaced.');
	
	% Cache some frequently used checks
	isvx = isvector(x);
	isvy = isvector(y);
	
	if (isvx && isvy)
		x = x(:);
		y = y(:);
		dim = 1;
	end
	
	% Get the original data dimensionalities
	szx = size(x);
	szy = size(y);
	xDimOrder = 1:ndims(x);
	yDimOrder = 1:ndims(y);
	
	% If necessary, permute the data arrays so that correlation occurs along the first dimension
	if dim ~= 1
		xDimOrder(1) = xDimOrder(dim);
		xDimOrder(dim) = 1;
		yDimOrder(1) = yDimOrder(dim);
		yDimOrder(dim) = 1;
		
		x = permute(x, xDimOrder);
		y = permute(y, yDimOrder);
	end
	
	% Capture any size changes if permutation took place
	szpx = size(x);
	szpy = size(y);
	assert(szpx(1) == szpy(1), 'Data arrays must be of equivalent size over the correlation dimension.');
	
	% Flatten the data arrays to two dimensions
	x = reshape(x, szpx(1), []);
	y = reshape(y, szpy(1), []);
	
	% If necessary, replicate vectors to create equally sized arrays
	if isvx; x = repmat(x, 1, size(y, 2)); end
	if isvy; y = repmat(y, 1, size(x, 2)); end
	assert(size(x, 2) == size(y, 2),...
		'Cross-correlation can only be estimated between vectors, an array and a vector, or two equally sized arrays.');
	
	% Compute the vector of sample lags
	maxLag = szpx(1) - 1;
	lags = -maxLag : maxLag;

	% Convert the coefficient scaling option to work with the MEX function
	opt = getOptCode(scaleOpt);
	
	% Estimate cross-correlation using the MEX function
% 	cc = MexCrossCorrelate(x, y, opt);
    if funOpt == 1
        cc = axcorrc(x, y);
    else
        cc = axcorrc2(x, y, opt);
    end
	szcc = size(cc);
	
	% Reshape the correlation data array to
	if (szcc(2) == prod(szpx(2:end)))
		cc = reshape(cc, [szcc(1), szpx(2:end)]);
		cc = permute(cc, xDimOrder);
	else
		cc = reshape(cc, [szcc(1), szpy(2:end)]);
		cc = permute(cc, yDimOrder);
	end
	
end



%% Subroutines
function opt = getOptCode(scaleOpt)

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

end