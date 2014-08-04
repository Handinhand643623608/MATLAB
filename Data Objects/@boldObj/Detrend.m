function Detrend(boldData, order)
%DETREND Detrend BOLD data time series.
%
%   SYNTAX:
%   Detrend(boldData, order)
%
%   INPUTS:
%   boldData:   BOLDOBJ
%               A BOLD data object containing a functional image time series to be detrended.
%
%   order:      INTEGER
%               Any positive integer representing the order of the detrending. 
%               EXAMPLES:
%                   1 - Linear detrend
%                   2 - Quadratic detrend
%                   3 - Cubic detrend
%                   .
%                   .
%                   .



%% CHANGELOG
%   Written by Josh Grooms on 20130919
%       20140612:   Updated the documentation for this method.
%       20140720:   Updated this function to work with the TOMATRIX method for BOLD data. 



%% Detrend the Functional Data Time Series
for a = 1:numel(boldData)
    % Get the current functional data & dimensions
    [funData, idsNaN] = ToMatrix(boldData(a));
    szData = size(boldData(a).Data.Functional);
    
    % Loop through each voxel series & detrend
    for b = 1:size(funData, 2)
        polyCoeffs = polyfit(1:szData(end), funData(b, :), order);
        funData(b, :) = funData(b, :) - polyval(polyCoeffs, 1:szData(end));
    end
    
    % Restore functional data array dimensions
    volData = nan(length(idsNaN), size(funData, 2));
    volData(~idsNaN, :) = funData;
    
    % Reshape the functional data array & store
    boldData(a).Data.Functional = reshape(volData, szData);
    boldData(a).IsZScored = false;
end