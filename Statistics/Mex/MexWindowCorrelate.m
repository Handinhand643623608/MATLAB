% MEXWINDOWCORRELATE - Computes the sliding window correlation between an array of signals and one or more other signals.
%	 
%	MEXWINDOWCORRELATE computes the sliding window correlation between two sets of signals over time. This creates a set of 
%	time series showing how correlation between two data sets changes as a function of time. It is particularly useful in  
%	analysing relationships between data that have non-stationary or time-varying statistical properties (such as my fMRI and 
%	EEG data).
%
%	SYNTAX:
%		swc = MexWindowCorrelate(x, y, window, noverlap)
%
%	OUTPUT:
%		swc:			[ MC x NC DOUBLES ]
%						An array of sliding window correlation values calculated between the data in X and Y. Each row of 
%						this array contains Pearson correlation coefficients (i.e. r values) between a specific segment of 
%						the signals in X and Y. The number of correlation time points MC will always follow this formula:
%
%							MC = floor( (M - WINDOW) / (WINDOW - NOVERLAP) )
%						
%						The number of correlation signals NC in this array will always follow NC = NX * NY in order to hold 
%						all possible pairings of signals. Each successive column in SWC then represents the correlation over 
%						time between one signal in Y and a successive signal in X. Each grouping of NX columns in this array 
%						therefore corresponds with the correlation between one signal in Y and all signals in X. Successive 
%						groupings correspond with successive signals in Y.
%
%	INPUTS:
%		x:				[ M x NX DOUBLES ]
%						An array of doubles containing the signal(s) to be correlated with each signal in Y. Each column of 
%						this array represents a single signal with M time points. The number of signals NX is free to vary 
%						but must be a positive integer. The number of time points M must always equal M from Y.
%
%		y:				[ M x NY DOUBLES ]
%						An array of doubles containing the signal(s) to be correlated with each signal in X. Each column of 
%						this array represents a single signal with M time points. The number of signals NY is free to vary 
%						but must be a positive integer. The number of time points M must always equal M from X.
%
%		window:			INT
%						The number of samples that constitute a single window. More specifically, this argument is the length 
%						of the window in signal samples. 
%
%		noverlap:		INT
%						The number of samples to be reused in successive correlation estimates. This is how many sample 
%						points are "overlapped" from previous estimates as the window slides along a signal. This argument 
%						must be an integer between 0 and WINDOW - 1.
%
%	See also: CCORR, SWCORR

%% CHANGELOG
%	Written by Josh Grooms on 20150204