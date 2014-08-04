function Regress(boldData, signal)
%REGRESS Linearly regress signals from BOLD functional time series.
%   This function performs a simple linear regression between a set of signals and all BOLD voxel time series, finding
%   the best fit (in the least-squares sense) for the signals to the data. It then scales the signals according to the
%   fitting parameters and subtracts them from the BOLD time series. Thus, the BOLD data that exists after this method
%   is called are the residual time series left over from the regression.
%
%   Linear regression is currently a popular method of removing artifacts from the BOLD data and accounting for signals
%   that are not likely to be neuronal in origin. Partial correlation, for instance, uses this approach to control for a
%   set of variables while estimating how two other data sets covary.
%
%   However, assuming simple linear relationships between complicated data (i.e. physiological data) is rarely exactly
%   correct. Care must be taken to ensure that the data fitting is approximately valid. If it is not, more complex
%   methods of regression may be called for.
%
%
%   SYNTAX:
%   Regress(boldData, signal)
%
%   INPUTS:
%   boldData:       BOLDOBJ
%                   A single BOLD data object.
%
%   signal:         1D ARRAY or 2D ARRAY
%                   A vector or array of signals to be regressed from the BOLD functional data. For either array size,
%                   the time dimension should span the rows of this input (i.e. [TIME x SIGNALS]).

%% CHANGELOG
%   Written by Josh Grooms on 20130919
%       20140612:   Updated the documentation of this method.
%       20140801:   Updated to work with the new MATFILE storage system.



%% Error Checking
% Prevent arrays of BOLD data objects from being inputted
if numel(boldData) > 1
    error('BOLD data objects must be inputted one at a time. Arrays of objects are not supported');
end

% Check that the signals being regressed are correctly oriented & are the right size
szSignal = size(signal);
szBOLD = size(boldData.Data.Functional);
if ~ismatrix(signal)
    error('The signals being regressed from BOLD data must be in a 1- or 2-dimensional array only');
elseif szSignal(1) ~= szBOLD(4)
    if szSignal(2) == szBOLD(4)
        signal = signal';
    else
        error('The signals being regressed must span the same length of time as the BOLD data');
    end
end

% Ensure that the first column in the signals being regressed are ones
if ~isequal(ones(size(signal, 1), 1), signal(:, 1))
    signal = [ones(size(signal, 1), 1), signal];
end

% Load any MATFILE data
LoadData(boldData);

    

%% Regress Signals from Functional Data
% Mask using the BOLD data mean image
Mask(boldData, 'mean', boldData.Preprocessing.Parameters.Conditioning.MeanCutoff, NaN);

% Flatten the functional data array
[functionalData, idsNaN] = ToMatrix(boldData, false);

% Extract non-NaN voxel series from the functional data
regFunctionalData = functionalData(~idsNaN, :);
regFunctionalData = regFunctionalData';

% Regress the inputted signals from the voxel time series
regFunctionalData = regFunctionalData - signal*(signal\regFunctionalData);
regFunctionalData = regFunctionalData';

% Restore the volumetric data array
functionalData(~idsNaN, :) = regFunctionalData;
functionalData = reshape(functionalData, szBOLD);

% Store the data in the object
boldData.Data.Functional = functionalData;
boldData.IsZScored = false;
