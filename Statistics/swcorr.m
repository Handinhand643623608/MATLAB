% SWCORR - Calculates the sliding window correlations between two data sets.
%
%	SWCORR computes the sliding window correlation between two sets of signals over time. This creates a set of time series
%	showing how correlation between two data sets changes as a function of time. It is particularly useful in analyzing
%	relationships between data that have non-stationary or time-varying statistical properties (such as my fMRI and EEG
%	data).
%
%	SYNTAX:
%		swc = swcorr(x, y, window)
%		swc = swcorr(x, y, window, noverlap)
%		swc = swcorr(x, y, window, noverlap, offset)
%
%	OUTPUT:
%		swc:			[ NC x NX x NY DOUBLES ]
%						An array of sliding window correlation values calculated between the data in X and Y. Each row of
%						this array contains Pearson correlation coefficients (i.e. r values) between specific segments of the
%						signals in X and Y. The number of correlation time points NC will always follow this formula:
%
%							NC = floor( (N - WINDOW) / (WINDOW - NOVERLAP) )
%						
%						The number of columns in this array will always equal the number of signals present in X, while the
%						number of pages NY will always equal the number of signals in Y. Thus, SWC(:, A, B) represents the
%						sliding window correlation between the two signals X(:, A) and Y(:, B). 
%
%	INPUTS:
%		x:				[ N x NX DOUBLES ]
%						An array of doubles containing the signal(s) to be correlated with each signal in Y. Each column of 
%						this array represents a single signal with N time points. The number of signals NX is free to vary 
%						but must be a positive integer. The number of time points N must always equal N from Y.
%	
%		y:				[ N x NY DOUBLES ]
%						An array of doubles containing the signal(s) to be correlated with each signal in X. Each column of 
%						this array represents a single signal with N time points. The number of signals NY is free to vary 
%						but must be a positive integer. The number of time points N must always equal N from X.
%
%		window:			INTEGER
%						The number of samples that constitute a single window. More specifically, this argument is the length
%						of the window in signal samples.
%
%	OPTIONAL INPUTS:
%		noverlap:		INTEGER
%						The number of samples to be reused in successive correlation estimates. This is how many sample
%						points are "overlapped" from the previous estimate as the window slides along a signal. This argument
%						must be an integer in the range [0, WINDOW - 1]. 
%						DEFAULT: WINDOW - 1
%
%		offset:			INTEGER
%						The sample offset to be applied between windows applied to X and Y. This argument is intended for use
%						when comparing signals with events that are delayed in time relative to one another. For example, in
%						my fMRI and EEG data, it is frequently expected that linked events occur ~4s (2 samples) apart from
%						one another because of the hemodynamic delay time.
%
%						Positive and negative integers may be provided for this argument. Signals in X and Y will be shifted
%						accordingly before any comparisons are made. Positive integers suggest that events in Y occur earlier
%						in time than any related events in X. Negative integers imply the reverse; events in Y occur after 
%						related events in X. For example, an offset of +A will result in windowed segments of X being
%						compared with windows A samples earlier in Y. The default value of this argument is no offset. 
%						DEFAULT: 0
%
%	See also: CCORR

%% CHANGELOG
%	Written by Josh Grooms on 20150204
%		20150511:	Re-implemented the C subroutine behind the actual SWC calculations in native MATLAB code so that this
%					function can still be used even when the MEX files I've written cannot.



%% FUNCTION DEFINITION
function swc = swcorr(x, y, window, noverlap, offset)

	% Check for errors in the mandatory input arguments
	assert(nargin > 2,...
		'A minimum of three arguments must be provided to this function. See documentation for syntax details.');
	
	assert(~isempty(x), 'X cannot be an empty array.');
	assert(ismatrix(x), 'X must be a vector or two-dimensional array.');
	assert(window > 0, 'The window length must always be a positive integer.');
	
	% Fill any missing inputs & error check others
	if isempty(y);		y = x;					end
	if nargin < 4;		noverlap = window - 1;	end
	if nargin < 5;		offset = 0;				end
	assert(ismatrix(y), 'Y must be a vector or two-dimensional array.');
	assert(noverlap >= 0 & noverlap < window,...
		'The number of overlapping samples between windows must be an integer in the range [0, WINDOW - 1].');
	
	% Ensure vectors are flattened
	if isvector(x); x = x(:); end
	if isvector(y); y = y(:); end
	szx = size(x);
	szy = size(y);
	
	assert(szx(1) == szy(1), 'X and Y must always contain the same number of time points.');
	
	% Apply a sample offset to the data, if necessary
	if (offset ~= 0)
		if (offset > 0)
			x = x((offset + 1) : end, :);
			y = y(1 : (end - offset), :);
		else
			offset = abs(offset);
			x = x(1 : (end - offset), :);
			y = y((offset + 1) : end, :);
		end
	end
	
	if (exist('MexWindowCorrelate', 'file') == 3)
		% Let the MEX function do the heavy lifting & then rearrange the output to the final format
		swc = MexWindowCorrelate(x, y, window, noverlap);
		swc = reshape(swc, size(swc, 1), szx(2), szy(2));
	else
		% Use native MATLAB code if the MEX function can't be used.
		swc = WindowCorrelate(x, y, window, noverlap);
	end
end



%% SUBROUTINES
function swc = WindowCorrelate(x, y, window, noverlap)
% WINDOWCORR - Calculate sliding window correlations using MATLAB language functions.
%
%	This function is used whenever the compiled MEX routine is unavailable. Unfortunately in those cases, this will require
%	significantly more time to complete.
%
%	OUTPUT:
%		swc:		[ NC x NX x NY DOUBLES ]
%					The correlation coefficient time series between all signals in X and Y.
%
%	INPUTS:
%		x:			[ N x NX DOUBLES ]
%					A matrix of signals whose samples span the rows of the array.
%
%		y:			[ N x NY DOUBLES ]
%					A matrix of signals whose samples span the rows of the array.
%
%		window:		INTEGER
%					The number of samples used per window segment.
%
%		noverlap:	INTEGER
%					The number of overlapping samples between successive window segments.
	
	szx = size(x);
	szy = size(y);
	increment = window - noverlap;
	nswc = floor((szx(1) - window) / increment);
	nsToUse = nswc * increment;	
	
	swc = zeros(nswc, szx(2), szy(2));	
	for a = 1:szy(2)		
		for b = 1:szx(2)
			idxSWC = 1;			
			for c = 1:increment:nsToUse
				tempcorr = corrcoef(x(c:c + window - 1, b), y(c:c + window - 1, a));
				swc(idxSWC, b, a) = tempcorr(2, 1);
				idxSWC = idxSWC + 1;
			end
		end
	end
end