function varargout = anticorrChannels(eegData, tolerance)
%ANTICORRCHANNELS Identify frequently anticorrelated EEG channels.
%
%   SYNTAX:
%   channels = anticorrChannels(eegData)
%   channels = anticorrChannels(eegData, tolerance)
%   [channels, freqMap] = anticorrChannels(...)
%
%   OUTPUTS:
%   channels:
%
%   OPTIONAL OUTPUT:
%   freqMap:
%
%   INPUT:
%   eegData:    An EEG data object.
%
%   OPTIONAL INPUT:
%   tolerance:  A scalar determining the tolerances for anticorrelated channel selection. A
%               tolerance greater than zero will result in a return of electrode pairs
%               anticorrelated to one another a number of times equal to the maximum minus the
%               tolerance value. For example, if the maximum number of times a channel pair is
%               anticorrelated to one another is 17, and the tolerance is 1, then all electrode
%               pairs that are anticorrelated to one another 16 times or greater will be returned.
%               DEFAULT: 0
%
%   Written by Josh Grooms on 20130815
%       20130829:   Updated to include a tolerance value & produce labeled figures.
%       20130902:   Removed progress bar (this function is fast on its own)


%% Identify Anticorrelated Electrodes
% Deal with missing inputs
if nargin == 1; tolerance = 0; end;

% Gather inter-electrode correlations across scans
corrMat = [];
upperCorrMat = [];
for a = 1:size(eegData, 1)
    for b = 1:size(eegData, 2)
        if ~isempty(eegData(a, b).Data)
            corrMat = cat(3, corrMat, corrcoef(eegData(a, b).Data.EEG'));
            upperCorrMat = cat(3, upperCorrMat, triu(corrMat(:, :, end)));
        end
    end
end

% Calculate frequency of anticorrelations across scans
idsAnticorr = upperCorrMat < 0;
freqAnticorr = sum(idsAnticorr, 3);

% Identify the most frequency anticorrelated electrodes
[idsRow, idsCol] = find(freqAnticorr >= (max(freqAnticorr(:)) - tolerance));
channels = [eegData(1, 1).Channels(idsRow), eegData(1, 1).Channels(idsCol)];

% Generate a sorted matrix & plot, if called for
if nargout == 2
    idsAnticorr = corrMat < 0;
    freqAnticorr = sum(idsAnticorr, 3);
    [freqAnticorr, idsSorted] = sortConnectivity(freqAnticorr);
    
    % Plot an incidence map for anticorrelated channels
    windowObj('size', 'fullscreen'); imagesc(freqAnticorr); axis square
    colorbar
    
    % Label the plot
    title('Sorted Frequency of Inter-Electrode Anticorrelations', 'FontSize', 16);
    allChannels = eegData(1, 1).Channels(idsSorted);
    labelFigure(...
        'tickDir', 'off',...
        'xLabels', allChannels(idsSorted),...
        'xRotation', 90,...
        'yLabels', allChannels(idsSorted));
end

assignOutputs(nargout, channels, freqAnticorr);


end%================================================================================================
%% Nested Functions
function [freqAnticorr, idsSorted] = sortConnectivity(freqAnticorr)
    [~, idsSorted] = sort(freqAnticorr);
    ascendCount = zeros(1, size(freqAnticorr, 1));
    for a = 1:size(idsSorted, 2)
        sortedFreqs = freqAnticorr(idsSorted(:, a), idsSorted(:, a));
        checkAscending = sortedFreqs(2:end, 2:end) > sortedFreqs(1:end-1, 1:end-1);
        ascendCount(a) = sum(checkAscending(:));
    end
    idsSorted = idsSorted(:, ascendCount == max(ascendCount));
    freqAnticorr = freqAnticorr(idsSorted, idsSorted);
end


