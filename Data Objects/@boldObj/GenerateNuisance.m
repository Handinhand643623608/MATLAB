function GenerateNuisance(boldData)
% GENERATENUISANCE - Estimate and store BOLD nuisance signals.
%
%   SYNTAX:
%   GenerateNuisance(boldData)
%
%   INPUTS:
%   boldData:       BOLDOBJ
%                   A single BOLD data object.

%% CHANGELOG
%   Written by Josh Grooms on 20130818
%       20130919:   Updated to work with improved MASK method.
%       20131030:   Major bug fix for how nuisance signals were being identified. Removed option for inputting which 
%                   nuisance parameters were being found. Now all of them are all the time.
%       20140612:   Updated the documentation for this method.
%       20140801:   Updated to work with the new MATFILE storage system.
%       20141001:   Completely rewrote this function so that it doesn't alter the data stored in the inputted object at
%                   all. Before, it was performing masking and z-scoring, which was fine for my data but might be
%                   unexpected for anyone who didn't follow my preprocessing procedure.



%% Generate & Store the Nuisance Signals
% Error checking
boldData.AssertSingleObject;
boldData.LoadData;

% Store a list of nuisance parameters
nuisanceStrs = {'Global', 'WM', 'CSF'};

% Get & flatten the functional data
funData = boldData.ToArray;
funData = maskImageSeries(funData, boldData.Data.Masks.Mean, NaN);
funData = reshape(funData, [], boldData.NumTimePoints);
funData = funData';

% Regress constant terms & motion parameters first
motionSigs = boldData.Data.Nuisance.Motion';
motionSigs = cat(2, ones(size(motionSigs, 1), 1), motionSigs);
funData = funData - motionSigs * (motionSigs \ funData);

for a = 1:length(nuisanceStrs)
    
    % Generate the nuisance signals & store them in the data object
    if (strcmpi(nuisanceStrs{a}, 'global'))
        nuisanceData = nanmean(funData, 2);
        boldData.Data.Nuisance.Global = nuisanceData';
    else
        segMask = boldData.Data.Masks.(nuisanceStrs{a})(:);
        nuisanceData = nanmean(funData(:, segMask), 2);
        boldData.Data.Nuisance.(nuisanceStrs{a}) = nuisanceData';
    end
    
    % Regress the current nuisance signal so that the next one isn't influenced by it
    funData = funData - nuisanceData * (nuisanceData \ funData);
end