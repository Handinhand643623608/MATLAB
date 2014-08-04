function GenerateNuisance(boldData)
%GENERATENUISANCE Estimate BOLD nuisance signals.
%
%   SYNTAX:
%   GenerateNuisance(boldData)
%
%   INPUTS:
%   boldData:       BOLDOBJ
%                   A BOLD data object or array of BOLD objects.

%% CHANGELOG
%   Written by Josh Grooms on 20130818
%       20130919:   Updated to work with improved MASK method.
%       20131030:   Major bug fix for how nuisance signals were being identified. Removed option for inputting which 
%                   nuisance parameters were being found. Now all of them are all the time.
%       20140612:   Updated the documentation for this method.
%       20140801:   Updated to work with the new MATFILE storage system.



%% Generate & Store the Nuisance Signals
% Z-Score & mask out functional image areas unlikely to contain tissue
ZScore(boldData);
meanCutoff = boldData(1).Preprocessing.Parameters.Conditioning.MeanCutoff;
Mask(boldData, 'mean', meanCutoff, NaN);
nuisanceStrs = {'Global', 'WM', 'CSF'};

for a = 1:numel(boldData)
    % Load any MATFILE data & get the flattened functional data
    LoadData(boldData(a));
    functionalData = ToMatrix(boldData(a));
    functionalData = functionalData';
    
    % Regress out motion data (always needed before identifying other nuisance parameters)    
    motionSigs = boldData(a).Data.Nuisance.Motion';
    functionalData = functionalData - motionSigs*(motionSigs\functionalData);
    
    % Identify nuisance signals by regressing out nuisance parameters that come before it
    for b = 1:length(nuisanceStrs)
        switch lower(nuisanceStrs{b})
            case 'global'
                nuisanceData = nanmean(functionalData, 2);
                boldData(a).Data.Nuisance.Global = nuisanceData';

            otherwise
                segmentData = reshape(boldData(a).Data.Segments.(nuisanceStrs{b}), [], 1)';
                nuisanceData = nanmean(functionalData(:, segmentData > meanCutoff), 2);
                boldData(a).Data.Nuisance.(nuisanceStrs{b}) = nuisanceData';
        end
        
        % Regress the current nuisance signal from functional data before identifying the next one
        functionalData = functionalData - nuisanceData*(nuisanceData\functionalData);
    end
end