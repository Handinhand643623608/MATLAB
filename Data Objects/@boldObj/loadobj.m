function output = loadobj(input)
%LOADOBJ - The update procedure for BOLD data objects loaded off of the hard drive.
%
%   SYNTAX:
%   output = boldObj.loadobj(input)
%
%   OUTPUT:
%   output:     BOLDOBJ or ANYTHING
%               An object of absolutely any type that is defined in MATLAB (including user-defined types) and is stored
%               inside of a .mat file. If the inputted object is a BOLD data object (of type boldObj), then this output
%               argument is also a BOLD data object, but the two may not be identical to one another. For example, if an
%               older data object is loaded, then this function may modify or perform updates on the object before it is
%               presented to the MATLAB workspace.
%
%   INPUT:
%   input:      BOLDOBJ or ANYTHING
%               An object of absolutely any type that is defined in MATLAB (including user-defined types) and is stored
%               inside of a .mat file. If this object is a BOLD data object (of type boldObj), then it is run through
%               this function's update procedure as necessary. Otherwise, this input becomes the LOADOBJ output without
%               any modifications.

%% CHANGELOG
%   Written by Josh Grooms on 20140720



%% Error Checking
% Determine the current software version for this data object
currentVersion = boldObj.LatestVersion;

% Check if the inputted object is a BOLD data object
boldObjCheck = isa(input(1), 'boldObj');
if boldObjCheck
    % Check for an up-to-date object (in order to return early)
    if isprop(input(1), 'SoftwareVersion')
        if isempty(input(1).SoftwareVersion)
            input(1).SoftwareVersion = 0;
        elseif (input(1).SoftwareVersion == currentVersion)
            output = input;
            return;
        end
    end
    
    % The object needs updating if this point is reached, so convert to a structure to simplify the process
    input = ToStruct(input);
else
    % If it's not, further checking is necessary (older objects fail the class check)
    boldObjCheck = isstruct(input(1)) && all(isfield(input(1), {'TR', 'TE', 'StoragePath'}));
    
    % If certain BOLD-specific fields aren't present, then it can't be a BOLD data object
    if ~boldObjCheck
        output = input;
        return;
    end
end



%% Create & Return Updated Data Objects
% Update the data structure to be compatible with current class versions
output(size(input)) = boldObj;
for a = 1:numel(input)
    if ~isfield(input(a), 'SoftwareVersion')
        input(a).SoftwareVersion = 0;
    end
    currentUpgrade = boldObj.upgrade(input(a));
    transferProperties(currentUpgrade, output(a));
end


end



%% Nested Functions
% Produce data objects from upgraded data structures
function transferProperties(boldStruct, boldData)
    propNames = fieldnames(boldStruct);
    for a = 1:length(propNames)
        boldData.(propNames{a}) = boldStruct.(propNames{a});
    end
end