function zscore(eegData)
%ZSCORE Scales EEG data to zero mean and unit variance.
% 
%   Written by Josh Grooms on 20130202
%       20130318:   Updated to reflect change in object properties & to make sure z-scoring is
%                   performed on correctly oriented data.


%% Initialize
% Get the number of subjects & scans for multidimensional EEG data objects
[numSubjects, numScans] = size(eegData);

%% Z-Score the Data
for idxSubject = 1:numSubjects
    for idxScan = 1:numScans
        if ~isempty(eegData(idxSubject, idxScan).Data)
            % Get the current data to be scaled
            currentEEG = eegData(idxSubject, idxScan).Data.EEG;
            currentBCG = eegData(idxSubject, idxScan).Data.BCG;
            currentGlobal = eegData(idxSubject, idxScan).Data.Global;
            
            % Make certain the data are in the correct format
            if iscolumn(currentBCG)
                currentBCG = currentBCG';
            end
            if iscolumn(currentGlobal)
                currentGlobal = currentGlobal';
            end
            
            % Scale the EEG data
            currentEEG = zscore(currentEEG, 0, 2);
            
            % Scale the BCG data, if available
            if ~isempty(currentBCG)
                currentBCG = zscore(currentBCG);
            end
            
            % Scale the global signal, if available
            if ~isempty(currentGlobal)
                currentGlobal = zscore(currentGlobal);
            end
            
            % Store the scaled data & change the check value
            eegData(idxSubject, idxScan).Data.EEG = currentEEG;
            eegData(idxSubject, idxScan).Data.BCG = currentBCG;
            eegData(idxSubject, idxScan).Data.Global = currentGlobal;
            eegData(idxSubject, idxScan).ZScored = true;
        end
    end
end
