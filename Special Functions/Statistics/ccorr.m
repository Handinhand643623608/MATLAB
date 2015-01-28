% CCORR - Estimates the cross-correlation function between data sets.
%
%	CCORR computes the Pearson product-moment cross-correlation between data just like the MATLAB-native statistical function
%	XCORR does, returning identical results when the 'coeff' scaling option is invoked. However, this function offers much
%	better performance than the native function does by wrapping a compiled C MEX function that was created using the Intel
%	C++ Optimizing Compiler (from the Composer XE 2015 suite). Consequently, this function is always faster than XCORR,
%	especially at large sample sizes. Benchmarks on large data (x = y = 218 x 226394) show that CCORR is ~3x faster than
%	XCORRARR and ~13x faster than using XCORR to accomplish the same task.
%
%	EXTREMELY IMPORTANT:
%		- The path to the Intel MKL libraries (.dll, not .lib) must currently be on the system's PATH environment
%		  variable. This really sucks, I know, but for reasons that aren't clear to me I couldn't get the MEX function
%		  to compile any other way, and it's potentially illegal for me to redistribute the MKL DLLs anyway. If you
%		  don't have the MKL libraries, this function cannot be used at all. 
%
%	SYNTAX:
%		cc = ccorr(x, y)
%       cc = ccorr(x, y, dim)
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
%   OPTIONAL INPUT:
%       dim:            INTEGER
%
%	See also: CORR2, CORR3, CORRCOEF, XCORR, XCORRARR

%% CHANGELOG
%	Written by Josh Grooms on 20150106

%% TODOS
%	- Finish documenting this function



%% Function Definition
function [cc, lags] = ccorr(x, y, dim)

	% Deal with missing inputs
	if nargin < 2;		y = x;				end
	if isempty(y);		y = x;				end
	if nargin < 3;		dim = 1;			end
	
	% Check for errors in inputs
	assert(~isempty(x), 'X cannot be an empty array.');
	hasNaN = any(isnan(x(:))) || any(isnan(y(:)));
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
	
	% Estimate cross-correlation using the MEX function
	cc = MexCrossCorrelate(x, y);
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