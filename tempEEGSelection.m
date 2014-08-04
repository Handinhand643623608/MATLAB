%TEMPEEGSELECTION Method for selecting EEG channels for BOLD-EEG correlation
%   
%   Written by Josh Grooms on 20130809

% Load infraslow, GSR EEG data
% if ~exist('eegData', 'var')
%     load eegObject_RS_dcGRZ_20130625
% end

% Concatenate inter-electrode correlations
corrMat = [];
pBar = progress('Subjects evaluated', 'Scans Evaluated');
for a = 1:size(eegData, 1)
    reset(pBar, 2);
    for b = 1:size(eegData, 2)
        if ~isempty(eegData(a, b).Data)
            % Take only the upper triangular part of correlation matrices
            corrMat = cat(3, corrMat, triu(corrcoef(eegData(a, b).Data.EEG')));
        end
        update(pBar, 2, b/size(eegData, 2));
    end
    update(pBar, 1, a/size(eegData, 1));
end
close(pBar);

% Flatten the correlation arrays
corrMat = reshape(corrMat, [], 17);

% Determine where anticorrelation occurs
idsAnticorr = corrMat < 0;

% Add together occurrences of anticorrelation (frequency of anticorr)
freqAnticorr = sum(idsAnticorr, 2);

% Find the maximum anticorrelation frequency electrode indices
idsAnticorrChans = find(freqAnticorr == max(freqAnticorr));
[idsRow, idsCol] = ind2sub([68, 68], idsAnticorrChans);

% Convert indices to electrode names
chans1 = eegData(1, 1).Channels(idsRow);
chans2 = eegData(1, 1).Channels(idsCol);



