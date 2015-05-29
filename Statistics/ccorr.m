% CCORR - Estimates the cross-correlation function between arrays of data.
%
%	CCORR computes the Pearson product-moment cross-correlation between data just like the MATLAB-native statistical function
%	XCORR does, returning identical results when the 'coeff' scaling option is invoked. However, this function offers much
%	better performance than the native function does by wrapping a compiled C MEX function that was created using the Intel
%	C++ Optimizing Compiler (from the Composer XE 2015 suite). Consequently, this function is always faster than XCORR, but
%	the effects are especially noticeable at large sample sizes. Benchmarks on large data ([300 x 250,000] arrays) show that
%	CCORR is ~15x faster than my old XCORRARR function and ~21x faster than manually iterating through signals using XCORR.
%
%	SYNTAX:
%       cc = ccorr(x)
%		cc = ccorr(x, y)
%       cc = ccorr(x, y, maxlag)
%		[cc, lags] = ccorr(...)
%
%	OUTPUTS:
%		cc:				[ MC x NX x NY DOUBLES ]
%                       An array of correlation values calculated between the data in X and Y. Each row of this array
%                       contains Pearson correlation coefficients (r values) between X and Y at a specific sample offset. The
%                       total number of offsets present will always follow MC = 2 * MAXLAG + 1. 
%
%                       The number of columns will always equal the number of signals present in X, while the number of pages
%                       will always equal the number of signals in Y. Thus, CC(:, A, B) represents the cross-correlation
%                       function between the two signals X(:, A) and Y(:, B).
%
%		lags:			[ MC x 1 INTEGERS ]
%                       A vector of sample shifts whose elements correspond with the rows in CC. This output helps identify
%                       at which lag or offset the values in each column of CC were derived.
%
%	INPUTS:
%		x:				[ M x NX DOUBLES ]
%                       An array of doubles containing the signal(s) to be cross-correlated with each signal in Y. Each
%                       column of this array represents a single signal with M time points. The number of signals NX is free
%                       to vary but must be a positive integer. The number of samples M must always equal M from Y. When X is
%                       the sole input or Y is an empty array, this function computes the autocorrelation of the signals in
%                       X.
%
%		y:				[ M x NY DOUBLES ]
%                       An array of doubles containing the signal(s) to be cross-correlated with each signal in X. Each
%                       column of this array represents a single signal with M time points. The number of signals NY is free
%                       to vary but must be a positive integer. The number of samples M must always equal M from X.
%                       DEFAULT: X
%
%       maxlag:         INTEGER
%                       The maximum number of sample shifts to use when calculating the cross-correlation. The output lags
%                       will then be the vector -MAXLAG : MAXLAG. The default value of this argument is the maximum possible
%                       sample shift, which is derived from the number of samples in X and Y.
%                       DEFAULT: M - 1
%
%	See also: CORR2, CORR3, CORRCOEF, XCORR, XCORRARR

%% CHANGELOG
%	Written by Josh Grooms on 20150106
%       20150131:   Completely rewrote this function in order to better define the scope in which it should be used. It's now
%                   somewhat less flexible than it was, but its speed is now significantly improved and its much less prone
%                   to errors. It also now handles single signals for either X or Y when the other argument is an array.
%                   Additionally, I completed the documentation for this function.
%		20150210:	Updated to remove the restrictions on the number of columns in X and Y. These can now freely vary.
%					Updated the documentation of this function to reflect this change and to improve clarity.
%		20150527:	Re-implemented the C subroutine behind the cross-correlation calculations in native MATLAB code so that
%					this function can still be used even when the MEX files I've written cannot.



%% FUNCTION DEFINITION
function [cc, lags] = ccorr(x, y, maxlag)

    % Check for errors in the X data argumment
    assert(~isempty(x), 'X cannot be an empty array.');
    assert(ismatrix(x), 'X must be a vector or two-dimensional array.');
    
    % Fill in any missing inputs & error check Y
    if nargin < 2;	y = x;                      end
    if nargin < 3;  maxlag = size(x, 1) - 1;    end
    if isempty(y);	y = x;                      end
    assert(ismatrix(y), 'Y must be a vector or a two-dimensional array.');
    
    % Flatten vectors
    if isvector(x); x = x(:); end
    if isvector(y); y = y(:); end
    szx = size(x);
    szy = size(y);
    
    % Constrain the size of X & Y
    assert(szx(1) == szy(1), 'X and Y must always contain the same number of samples.');
    
	if (exist('MexCrossCorrelate', 'file') == 3)	
		% Let the MEX function do the heavy lifting to calculate cross-correlation
		if (szx(2) == 1 && szy(2) ~= 1)
			cc = flip(MexCrossCorrelate(y, x));
		else
			cc = MexCrossCorrelate(x, y);
		end
	else
		% Use native MATLAB code if the MEX function can't be used
		cc = CrossCorrelate(x, y);
	end
	
    % Remove unwanted shifts
    allLags = -(szx(1) - 1) : (szx(1) - 1);
    lags = -maxlag : maxlag;
    idsLagsToKeep = ismember(allLags, lags);
    cc = cc(idsLagsToKeep, :);
    
	% Rearrange the output to a more intuitive format
	cc = reshape(cc, size(cc, 1), szx(2), szy(2));
	lags = lags';
	
end



%% SUBROUTINES
function cc = CrossCorrelate(x, y)
% CROSSCORRELATE - Calculate cross-correlation between arrays of signals using MATLAB language functions.
%
%	This function is used whenever the compiled MEX routine is unavailable. Unfortunately in those cases, this will require
%	significantly more time to complete.
%
%	OUTPUT:
%		cc		[ MC x NC DOUBLES ]
%				The Pearson correlation coefficients at all possible time lags between the signals in x and y. The number of
%				columns (NC) of this array is the product of NX and NY. This output is a flattened version of the ultimate
%				output of CCORR.
%
%	INPUTS:
%		x:		[ M x NX DOUBLES ]
%				A matrix of signals whose samples span the rows of the array.
%
%		y:		[ M x NY DOUBLES ]
%				A matrix of signals whose samples span the rows of the array.

	% Acquire some data characteristics
	szx = size(x);
	szy = size(y);
	ncc = 2 * szx(1) - 1;
	nfft = 2^nextpow2(ncc);
	
	% Cross-correlation of large signals is efficiently performed in the frequency domain
	X = fft(x, nfft, 1);
	Y = fft(y, nfft, 1);
	
	% Initialize storage arrays for the cross-spectral density data & Pearson r scaling coefficients
	CC = zeros(nfft, szx(2) * szy(2));
	scale = zeros(1, szx(2) * szy(2));
	
	% Calculate cross-spectral densities between individual signals in x and y
	idxColCC = 1;
	for a = 1:szy(2)
		for b = 1:szx(2)
			
			% CC is the cross-spectral density of X and Y and is the Fourier transform of the cross-covariance function.
			% Scaling coefficients are also derived from the original signals that will later be used to convert
			% cross-covariance estimates into Pearson correlation coefficients. The counter here (index of the CC column
			% being computed) isn't necessary but is more transparent and more efficient than calculating it on-the-fly.

			CC(:, idxColCC) = X(:, b) .* conj(Y(:, a));
			scale(idxColCC) = sum(abs(x(:, b)).^2) * sum(abs(y(:, a)).^2);
			idxColCC = idxColCC + 1;
			
		end
	end
	
	% Convert the cross-spectral densities to cross-covariance functions & unshift the data
	cc = real(ifft(CC, [], 1));
	cc = [ cc(end-szx(1)+2:end, :); cc(1:szx(1), :) ];
	
	% Scale cross-covariance estimates to Pearson product-moment correlation coefficients
	scale = repmat(sqrt(scale), ncc, 1);
	cc = cc ./ scale;
	
end