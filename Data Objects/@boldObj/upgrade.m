function boldStruct = upgrade(boldStruct)
%UPGRADE - Upgrades BOLD data objects for compatibility with newer class software.
%
%   SYNTAX:
%   boldStruct = boldObj.upgrade(boldStruct)
%
%   OUTPUT:
%   boldStruct:     SRUCT
%                   The upgraded version of the inputted BOLD data object. Although still a structure by type, this
%                   updated object has been reformatted for compatibility with the newest versions of the class code
%                   behind human and BOLD data objects. It will be converted to the BOLDOBJ class during the last stage
%                   of LOADOBJ.
%
%   INPUT:
%   boldStruct:     STRUCT
%                   An old BOLD data object loaded from a .mat file that must be upgraded before being usable. This data
%                   object is provided as a structure formatted according to an older version of the class code behind
%                   human and BOLD data objects code. The use of structures here is necessary to prevent losses of
%                   information that occur when MATLAB truncates objects to fit new class definitions.

%% CHANGELOG
%   Written by Josh Grooms on 20140720


%% Upgrade the Inputted Data Structure
% Get the software version used to build the inputted data structure
dataVersion = boldStruct.SoftwareVersion;

% Upgrade from version 0 to version 1
if dataVersion == 0
    boldStruct = humanObj.upgrade(boldStruct);
end