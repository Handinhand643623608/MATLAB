function dataStruct = upgrade(dataStruct)
%UPGRADE - Implements any changes to human data objects in older stored objects.
%
%   SYNTAX:
%   dataStruct = humanObj.upgrade(dataStruct)
%
%   OUTPUT:
%   dataStruct:     STRUCT
%                   A data structure that is an older human data object and is currently being loaded from the hard
%                   drive.
%
%   INPUT:
%   dataStruct:     STRUCT
%                   An updated version of the data structure that was inputted. Any changes that have been made to the
%                   core HUMANOBJ since the inputted structure was created should be applied. 

%% CHANGELOG
%   Written by Josh Grooms on 20140714



%% Perform Universal Data Structure Upgrades
% Get the software version used to build the inputted data structure
dataVersion = dataStruct.SoftwareVersion;

% Update from version 0 to version 1
if dataVersion == 0
    if isfield(dataStruct, 'GSR')
        dataStruct.IsGlobalRegressed = dataStruct.GSR;
        dataStruct = rmfield(dataStruct, 'GSR');
    elseif isfield(dataStruct, 'GlobalRegressed')
        dataStruct.IsGlobalRegressed = dataStruct.GlobalRegressed;
        dataStruct = rmfield(dataStruct, 'GlobalRegressed');
    else
        dataStruct.IsGlobalRegressed = false;
    end
    
    if isempty(dataStruct.IsGlobalRegressed)
        dataStruct.IsGlobalRegressed = false;
    end
    
    dataStruct.IsFiltered = dataStruct.Filtered;
    dataStruct.IsZScored = dataStruct.ZScored;
    
    dataStruct = rmfield(dataStruct, {'Filtered', 'ZScored'});
    dataStruct.SoftwareVersion = '1';
end