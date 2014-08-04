function Standardize(eegData)
%STANDARDIZE Makes the size of all EEG data matrices consistent.
%   Certain subjects in the collected data set have a non-standard number of electrodes. This function adds rows of NaNs
%   to the EEG data matrix where electrodes are missing in order to standardize the matrix layout across all data.
%
%   SYNTAX:
%   Standardize(eegData)
%
%   INPUTS:
%   eegData:    EEGOBJ
%               A single, unstandardized EEG data object. 

%% CHANGELOG
%   Written by Josh Grooms on 20130625
%       20140714:   Removed dependency on my personal file and parameter structures (where all EEG channel labels were
%                   coming from here). Replaced this with a small .mat file that contains channel labels and is intended
%                   to move with the EEG data object class files. Changed this method to only accept single data object
%                   inputs instead of arrays.



%% Error Checking
CheckCorrectObject(eegData);
CheckSingleObject(eegData);



%% Initialize
[eegObjPath, ~, ~] = fileparts(which('eegObj.m'));
load([eegObjPath '/AllChannels.mat']);

% Workaround for MATFILE data storage system
if isa(eegData.Data, 'matlab.io.MatFile')
    eegData.Data = load(eegData.Data.Properties.Source);
end



%% Standardize the Data Arrays
currentStdData = zeros(length(allChannels), size(eegData.Data.EEG, 2));
memberCheck = ismember(allChannels, eegData.Channels);
currentStdData(~memberCheck, :) = NaN;
currentStdData(memberCheck, :) = eegData.Data.EEG;
eegData.Data.EEG = currentStdData;
eegData.Channels = allChannels;            