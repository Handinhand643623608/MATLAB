function ZScore(dataObject)
%ZSCORE - Scales primary object data to signals of zero mean and unit variance.
%   This function converts BOLD and EEG time series data with arbitrary amplitude units to standard scores. Standard
%   scoring re-expresses data as a fraction of the data's standard deviation. 
%
%   The ZSCORE function of this class operates only on primary data signals. For EEG objects, this includes only the EEG
%   channel signals. For BOLD objects, this includes only the voxel signals from the functional images. Other data that
%   might be present in the data object (e.g. nuisance signals such as white matter, motion, BCG, or global signals) are
%   NOT z-scored. Such signals must be manually extracted and converted if so desired.
%
%   Z-scoring here operates on individual signals over time in the following way. First, the average of each signal over
%   time is calculated and subtracted away from every time point in that signal. Often called "mean centering" because
%   it centers the signal about the time axis, this makes the average signal amplitude zero. Second, the standard
%   deviation of each signal is calculated and divided away from every time point in the signal. This scales amplitude
%   values so that they are represented as some fraction of the entire signal's standard deviation. Overall, the formula
%   for any signal X is as follows:
%
%       Y = (X - mean(X)) ./ std(X)
%
%   Any NaNs in the data are ignored and do not contribute to estimates of means or standard deviations except by
%   lowering the sample count for a signal.
%
%   SYNTAX:
%   ZScore(dataObject)
%
%   INPUT:
%   dataObject:     HUMANOBJ
%

%% CHANGELOG
%   Written by Josh Grooms on 20140711


%% ZScore Data from the Object
% Get the primary data from the data object
dataArray = ToArray(dataObject);

% Workaround for MATFILE data storage
LoadData(dataObject);

% Find the time dimension of the data (always the last dimension) & other sizing quantities
szData = size(dataArray);
dim = length(szData);
repDims = [ones(1, dim - 1), szData(end)];

% Calculate the mean & standard deviation, ignoring any NaNs
avg = nanmean(dataArray, dim);
sigma = nanstd(dataArray, 0, dim);

% Z-score the data
dataArray = dataArray - repmat(avg, repDims);
dataArray = dataArray ./ repmat(sigma, repDims);

% Store standardized data in the data object

