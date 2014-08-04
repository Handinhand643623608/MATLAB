function dataObject = loadObj(dataFile)
%LOADOBJ Load a data structure from file storage and restore it to its original object class. This
%   function is a temporary solution for a known bug in MATLAB OOP that has already been fixed in
%   the latest release. 
%
%   Written by Josh Grooms 20130324


%% Load the File
% Load
temp = load(dataFile);
dataStruct = fieldnames(temp);

% Determine which object class to use for construction
switch dataStruct{1}
    case 'boldData'
        dataObject = boldObj(temp.boldData);
        
    case 'eegData'
        dataObject = eegObj(temp.eegData);
        
    case 'relationData'
        dataObject = relationObj(temp.relationData);
        
    otherwise
        error(['Conversion between structure and object not supported for structure ' fieldnames(temp) ]);
end

