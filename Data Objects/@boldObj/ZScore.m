function ZScore(boldData)
%ZSCORE Scales BOLD voxel time courses to zero mean and unit variance.
%   This function converts BOLD voxel time series with arbitrary amplitude units to standard scores. Standard scoring
%   re-expresses data as a fraction of the data's standard deviation. In this case, for any given BOLD voxel data point,
%   the average amplitude over all time is subtracted away and the data point is then divided by the standard deviation
%   of the voxel signal. 
%
%
%   SYNTAX:
%   ZScore(boldData)
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A BOLD data object or array of objects with functional time series to be standard scored.

%% CHANGELOG
%   Written by Josh Grooms on 20130320
%       20130818:   Removed global signal zscoring (may not be appropriate)
%       20140612:   Updated the documentation for this method.



%% Z-Score the Data
for i = 1:numel(boldData)    
    % Get the current data to be normalized
    currentBOLD = boldData(i).Data.Functional;
        
    % Normalize
    currentBOLD = zscore(currentBOLD, 0, 4);
    
    % Store the data in the object
    boldData(i).Data.Functional = currentBOLD;
    boldData(i).IsZScored = true;
end


                