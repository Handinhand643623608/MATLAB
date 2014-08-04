function eegData = checkZScore(eegData)
%CHECKZSCORE Checks if the data in the EEG object has been scaled to zero mean & unit variance.
% 
%   Written by Josh Grooms on 20130202
%       20130318:   Updated function to use "sigFig" & improved mean/variance checks


%% Check for Z-Scoring of the Input Data
% Get the size of the input
szObj = size(eegData);
for idxSubject = 1:szObj(1)
    for idxScan = 1:szObj(2)
        % Get the current data to be analyzed
        currentEEG = eegData(idxSubject, idxScan).Data.EEG;
        currentBCG = eegData(idxSubject, idxScan).Data.BCG;
        
        % If the data set is empty, z-scoring is not relevant. Otherwise, proceed with the check
        if isempty(currentEEG)
            eegData(idxSubject, idxScan).ZScored = [];
        else
            % Check the mean & variance of the EEG data
            currentMeanEEG = mean(currentEEG, 2);
            currentMeanEEG = sigFig(currentMeanEEG, 'format', '0.00', 'option', 'round');
            currentMeanCheck = sum(currentMeanEEG ~= 0);
            currentVarEEG = var(currentEEG, 0, 2);
            currentVarEEG = sigFig(currentVarEEG, 'format', '0.00', 'option', 'round');
            currentVarCheck = sum(currentVarEEG ~= 1);
            
            % Check the mean & variance of the BCG data (if it exists)
            if ~isempty(currentBCG)
                currentMeanBCG = mean(currentBCG);
                currentMeanBCGCheck = round(currentMeanBCG) ~= 0;
                currentVarBCG = var(currentBCG);
                currentVarBCGCheck = round(currentVarBCG) ~= 1;
            else
                currentMeanBCGCheck = 0;
                currentVarBCGCheck = 0;
            end
            
            % Change the value of the z-score property in the data object, as needed
            if currentVarCheck || currentMeanCheck || currentMeanBCGCheck || currentVarBCGCheck
                eegData(idxSubject, idxScan).ZScored = false;
            else
                eegData(idxSubject, idxScan).ZScored = true;
            end
        end
    end
end

            
            