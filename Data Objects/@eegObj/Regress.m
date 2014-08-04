function Regress(eegData, signal)
%REGRESS Linearly regress signals from EEG time series.
%   This function performs a simple linear regression between a set of signals and all EEG channel time series, finding
%   the best fit (in the least-squares sense) for the signals to the data. It then scales the signals according to the
%   fitting parameters and subtracts them from the EEG time series. Thus, the EEG data that exists after this method is
%   called are the residual time series left over from the regression.
%
%   Linear regression is currently a popular method of removing artifacts from the EEG data and accounting for signals
%   that are not likely to be neuronal in origin. Partial correlation, for instance, uses this approach to control for a
%   set of variables while estimating how two other data sets covary. 
%
%   However, assuming simple linear relationships between complicated data (i.e. physiological data) is rarely exactly
%   correct. Care must be taken to ensure that the data fitting is approximately valid. If it is not, more complex
%   methods of regression may be called for.
%
%   SYNTAX:
%   Regress(eegData, signal)
%
%   INPUTS:
%   eegData:        EEGOBJ
%                   A single EEG data object.
%
%   signal:         1D ARRAY or 2D ARRAY
%                   A vector or array of signals to be regressed from the EEG channel data. For either array size, the
%                   time dimension should span the rows of this input (i.e. [TIME x SIGNALS]);

%% CHANGELOG
%   Written by Josh Grooms on 20140617



%% Error Checking

if numel(eegData) > 1
    error('EEG data objects must be inputted one at a time. Arrays of objects are not supported');
end

% Check that the signals being regressed are correctly oriented & are the right size
szSignal = size(signal);
szEEG = size(eegData.Data.EEG);
if ~ismatrix(signal)
    error('The signals being regressed from BOLD data must be in a 1- or 2-dimensional array only');
elseif szSignal(1) ~= szEEG(2)
    if szSignal(2) == szEEG(2)
        signal = signal';
    else
        error('The signals being regressed must span the same length of time as the EEG data');
    end
end

% Ensure that the first column in the signals being regressed are ones
if ~isequal(ones(size(signal, 1), 1), signal(:, 1))
    signal = cat(2, ones(size(signal, 1)), signal);
end


%% Regress Signals from EEG Data
% Get the EEG data array
ephysData = eegData.Data.EEG;

% Remove any dead channels
idsNaN = isnan(ephysData(:, 1));
regEphysData = ephysData(~idsNaN, :);
regEphysData = regEphysData';

% Regress the signals from the channel time series
regEphysData = regEphysData - signal*(signal\regEphysData);
regEphysData = regEphysData';

% Restore the original data array
ephysData(~idsNaN, :) = regEphysData;

% Store the regressed data in the object
eegData.Data.EEG = ephysData;
eegData.ZScored = false;

end

