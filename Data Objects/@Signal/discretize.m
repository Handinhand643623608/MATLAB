function y = discretize(x, nbins, partition)
%DISCRETIZE Re-expresses signal amplitude in terms of its membership with discrete partitions. 
%
%   SYNTAX:
%   y = discretize(x)
%   y = discretize(x, nbins)
%   y = discretize(x, nbins, dist)
%
%   OUTPUT:
%   y:              VECTOR
%                   A one-dimensional vector of data the same size as the input signal. This output represents the
%                   discretized version of x, where continuous amplitude values have been converted into discrete
%                   integers with a range of [1, nbins+1]. How continuous values are grouped together, or binned,
%                   depends on the partition parameter. 
%
%                   If partition boundaries are equidistant, then the number of data points per bin depends entirely on
%                   the distribution of amplitude values. Otherwise, if each partition is equiprobable, then there will
%                   be roughly an equal number of data points from x per bin. However, there will be some variability in
%                   the actual number of points per bin if the signal length is not evenly divisible by the number of
%                   bins requested.
%
%   INPUT:
%   x:              VECTOR
%                   A one-dimensional vector of data representing a signal.
%
%   OPTIONAL INPUTS:
%   nbins:          INTEGER
%                   The number of bins to be used. The default value of this variable assumes that the signal has been
%                   z-scored and that amplitudes vary between about +/- 3 standard deviations.
%                   DEFAULT: 6
%
%   partition:      STRING
%                   A string dictating how to partition the data. The default value of this parameter attempts to group
%                   a z-scored signal roughly by its standard deviations.
%                   DEFAULT: 'Equidistant'
%                   OPTIONS:
%                            'Equidistant'  - Discretize amplitudes using evenly spaced bins that span the data range.
%                            'Equiprobable' - Discretize by assigning an equal number of data points per individual bin.
%                           

%% CHANGELOG
%   Written by Josh Grooms on 20140623



%% Error Checking
% Fill in missing inputs
if nargin == 1
    nbins = 6;
    partition = 'equidistant';
elseif nargin == 2
    partition = 'equidistant';
end

% Ensure that the input is a vector
if ~isvector(x)
    error('Inputted data must be a one-dimensional vector only. Multiple signals are not supported');
end



%% Discretize the Signal
y = x;
switch lower(partition)
    case 'equiprobable'
        % Bin the signal into equiprobable partitions
        sortedX = sort(x);
        numPerBin = floor(numel(x)/nbins);
        for a = 1:nbins
            idxStart = (a-1)*numPerBin + 1;
            binMax = sortedX(idxStart + numPerBin);
            y(x <= binMax) = a;
            x(x <= binMax) = NaN;
        end
        
    case 'equidistant'
        % Bin the signal into evenly spaced partitions        
        binVals = linspace(min(x), max(x), nbins + 1);
        
        for a = 1:length(binVals)
            y(x <= binVals(a)) = a;
            x(x <= binVals(a)) = NaN;
        end
end      