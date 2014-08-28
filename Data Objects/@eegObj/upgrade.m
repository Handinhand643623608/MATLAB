function eegStruct = upgrade(eegStruct)
%UPGRADE - Upgrades EEG data objects for compatibility with newer class software.
%
%   SYNTAX:
%   eegStruct = eegObj.upgrade(eegStruct)
%
%   OUTPUT:
%   eegStruct:      STRUCT
%                   The upgraded version of the inputted EEG data object. Although still a structure by type, this
%                   updated object has been reformatted for compatibility with the newest versions of the class code
%                   behind human and EEG data objects. It will be converted to the EEGOBJ class during the last stage of
%                   LOADOBJ.
%
%   INPUT:
%   eegStruct:      STRUCT
%                   An old EEG data object loaded from a .mat file that must be upgraded before being usable. This data
%                   object is provided as a structure formatted according to an older version of the class code behind
%                   human and EEG data objects code. The use of structures here is necessary to prevent losses of
%                   information that occur when MATLAB truncates objects to fit new class definitions.

%% CHANGELOG
%   Written by Josh Grooms on 20140714



%% Upgrade the Inputted Data Structure
% Get the software version used to build the inputted data structure
dataVersion = eegStruct.SoftwareVersion;

% Update from version 0 to version 1
if dataVersion == 0
    eegStruct = humanObj.upgrade(eegStruct);
end

