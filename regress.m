function regress(boldData, regSignal)
%REGRESS Regress signals from BOLD voxel time series
%
%   SYNTAX:
%   regress(boldData, regSignal)
%
%   INPUTS:
%   boldData:       A BOLD data object.
%
%   regSignal:      A string or cell array of strings representing the signal(s) to regress from the
%                   BOLD data. 
%
%   Written by Josh Grooms on 20130818


%% Regress Signals from BOLD Data
if ~iscell(regSignal); regSignal = {regSignal}; end
for a = 1:length(boldData)
    % Use the mean image as a general brain mask
    meanData = boldData(a).Data.Mean;
    meanData = reshape(meanData, [], 1);
    idsBrain = meanData > boldData(a).Preprocessing.Parameters.Conditioning.MeanCutoff;
    
    % Gather the functional data & mask using the mean image
    functionalData = boldData(a).Data.Functional;
    szBOLD = size(functionalData);
    functionalData = reshape(functionalData, [], size(functionalData, 4));
    
    for b = 1:length(regSignal)
        generateNuisance(boldData(a), regSignal);
        currentRegSignal = boldData(a).Data.Nuisance.(regSignal{b});
        
        % Regress the signal from the functional data
        functionalData(idsBrain, :) = regressSignal(functionalData(idsBrain, :), currentRegSignal);
    end

    boldData(a).Data.Functional = reshape(functionalData, szBOLD);
end