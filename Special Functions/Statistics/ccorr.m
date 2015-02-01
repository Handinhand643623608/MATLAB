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
%		cc:				[ NCC x NS DOUBLES ]
%                       The normalized correlation coefficients between the signals in X and Y at the sample offsets in LAGS.
%                       If Y is empty or omitted, then this is the autocorrelation function of the signals in X. This output
%                       will contain a fixed number of rows NCC dictated by the MAXLAG argument: NCC = 2 * MAXLAG + 1. The
%                       number of signal correlates NS will always be the greater of NX and NY.
%
%		lags:			[ NCC x 1 INTEGERS ]
%                       A vector of sample shifts whose elements correspond with the rows in CC. This output helps identify
%                       at which lag or offset the values in each column of CC were derived.
%
%	INPUTS:
%		x:				[ M x NX DOUBLES ]
%                       A column vector or matrix of signals to be cross-correlated with the data in Y. The number of rows in
%                       this argument should represent the number of samples in the signal(s) being correlated. The number of
%                       columns NX then represents the number of signals that are present in the data set. When X is the sole
%                       input or Y is an empty array, this function computes the autocorrelation of the signals in X. This
%                       argument cannot contain NaNs.
%
%		y:				[ M x NY DOUBLES ]
%                       DEFAULT: X
%                       A column vector or matrix of signals to be cross-correlated with the data in X. Like X, the rows of
%                       this argument represent individual signal samples, while columns represent the signals themselves.
%                       The number of samples M in this argument must always equal the number of samples in X. This argument
%                       also cannot contain NaNs.
%
%                       When the argument X is a single column vector, the number of columns NY here is free to vary. This
%                       scenario would then represent a single signal X being cross-correlated with all signals in Y.
%                       However, when X is a matrix with NX > 1, NY must either be 1 or must equal NX. This corresponds with
%                       a set of signals X being cross-correlated with either a single signal or equivalently sized set of
%                       signals Y. If empty or omitted, this argument becomes a copy of X to produce the autocorrelation
%                       estimate of X.
%
%       maxlag:         INTEGER
%                       DEFAULT: M - 1
%                       The maximum number of sample shifts to use when calculating the cross-correlation. The output lags
%                       will then be the vector -MAXLAG : MAXLAG. The default value of this argument is the maximum possible
%                       sample shift, which is derived from the number of samples in X and Y.
%
%	See also: CORR2, CORR3, CORRCOEF, XCORR, XCORRARR

%% CHANGELOG
%	Written by Josh Grooms on 20150106
%       20150131:   Completely rewrote this function in order to better define the scope in which it should be used. It's now
%                   somewhat less flexible than it was, but its speed is now significantly improved and its much less prone
%                   to errors. It also now handles single signals for either X or Y when the other argument is an array.
%                   Additionally, I completed the documentation for this function.



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

    % X & Y cannot have NaNs
    hasNaN = any(isnan(x(:))) || any(isnan(y(:)));
	assert(~hasNaN,...
        'NaNs were detected in one or more inputted data sets. These must be removed or replaced before invoking this function.');
    
    % Flatten vectors
    if isvector(x); x = x(:); end
    if isvector(y); y = y(:); end
    szx = size(x);
    szy = size(y);
    
    % Constrain the size of X & Y
    assert(szx(1) == szy(1), 'X and Y must always contain the same number of rows.');
    if (szx(2) ~= 1 && szy(2) ~= 1)
        assert(szx(2) == szy(2), 'When X and Y are matrices, they must both contain the same number of columns.');
    end
    
    % Cross correlate the data
    if (szx(2) == 1 && szy(2) ~= 1)
        cc = flip(MexCrossCorrelate(y, x));
    else
        cc = MexCrossCorrelate(x, y);
    end
        
    % Remove unwanted shifts
    allLags = -(szx(1) - 1) : (szx(1) - 1);
    lags = -maxlag : maxlag;
    idsLagsToKeep = ismember(allLags, lags);
    cc = cc(idsLagsToKeep, :);
    lags = lags';
	
end