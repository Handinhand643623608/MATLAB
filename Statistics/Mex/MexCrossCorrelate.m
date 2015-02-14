% MEXCROSSCORRELATE  - Computes the cross-correlations between two sets of signals.
%
%	SYNTAX:
%		cc = MexCrossCorrelate(x, y)
%
%	OUTPUT:
%		cc:				[ MC x NC DOUBLES ]
%                       An array of correlation values calculated between the data in X and Y. Each row of this array
%                       contains Pearson correlation coefficients (i.e. r values) between X and Y at a specific sample
%                       offset. The total number of offsets present will always follow MC = 2 * M - 1. 
%   
%  						The number of correlation signals NC in this array wil always follow NC = NX * NY in order to hold 
%  						all possible pairings of signals. Each successive column in CC then represents the correlation at all 
%  						offsets between one signal in Y and a successive signal in X. Each contiguous grouping of NX columns 
%  						in this array therefore corresponds with the correlation between one signal in Y and all signals in 
%  						X. Successive groupings corresponds with successive signals in Y.
%
%	INPUT:
%		x:				[ M x NX DOUBLES ]
%                       An array of doubles containing the signal(s) to be cross-correlated with each signal in Y. Each
%                       column of this array represents a single signal with M time points. The number of signals NX is free
%                       to vary but must be a positive integer. The number of samples M must always equal M from Y.
%
%		y:				[ M x NY DOUBLES ]
%                       An array of doubles containing the signal(s) to be cross-correlated with each signal in X. Each
%                       column of this array represents a single signal with M time points. The number of signals NY is free
%                       to vary but must be a positive integer. The number of samples M must always equal M from X.
%
%   See also: CCORR, XCORR

%% CHANGELOG
%   Written by Josh Grooms on 20150131
%		20150210:	Updated to remove the restrictions on the number of columns in X and Y. These can now freely vary.
%					Updated the documentation of this function to reflect this chang and to improve clarity.