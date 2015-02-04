% MEXCROSSCORRELATE  - Computes the cross-correlations between two sets of signals.
%
%	SYNTAX:
%		cc = MexCrossCorrelate(x, y)
%
%	OUTPUT:
%		cc:				[ NCC x NX DOUBLES ]
%                       The normalized correlation coefficients between the signals in X and Y at every possible sample
%                       offset. This output will contain a fixed number of rows NCC determined by the number of samples in
%                       the signals in X and Y: NCC = 2 * M - 1. 
%
%	INPUT:
%		x:				[ M x NX DOUBLES ]
%                       A column vector or matrix of signals to be cross-correlated with the data in Y. The number of rows in
%                       this argument should represent the number of samples in the signal(s) being correlated. The number of
%                       columns NX then represents the number of signals that are present in the data set. This argument
%                       cannot contain NaNs.
%
%		y:				[ M x NY DOUBLES ]
%                       A column vector or matrix of signals to be cross-correlated with the data in X. Like X, the rows of
%                       this argument represent individual signal samples, while columns represent the signals themselves.
%                       The number of samples M in this argument must always equal the number of samples in X. This argument
%                       also cannot contain NaNs. The number of signals NY must either be 1 or NX.
%
%   See also: CCORR, XCORR, XCORRARR

%% CHANGELOG
%   Written by Josh Grooms on 20150131