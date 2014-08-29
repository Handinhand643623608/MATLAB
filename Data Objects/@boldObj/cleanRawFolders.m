function CleanRawFolders(inPath, varargin)
%CLEANRAWFOLDERS Cleans out files generated during raw data preprocessing.
%
%   SYNTAX:
%   CleanRawFolders(inPath, 'PropertyName', PropertyValue...)
%   
%   INPUTS:
%   inPath:                     STRING
%                               The uppermost path to the raw data folders. This string should point to the folder
%                               containing all individual subject folders.
%   
%   OPTIONAL INPUTS: 
%   'AnatomicalFolderStr':      STRING
%                               The string designation for all anatomical data folders.
%                               DEFAULT: 't1_MPRAGE'
%
%   'FunctionalFolderStr':      STRING
%                               The string designation for all functional data folders.
%                               DEFAULT: 'ep2d'
%
%   'SubjectFolderStr':         STRING
%                               The string designation for all subject data folders.
%                               DEFAULT: '1..A_'



%% CHANGELOG
%   Written by Josh Grooms on 20130619
%       20130707:   Updated defaults for use on my home computer
%       20130711:   Changed input variable names to ones that actually make sense. Some small bug fixes.



%% Initialize
inStruct = struct(...
    'AnatomicalFolderStr', 't1_MPRAGE',...
    'FunctionalFolderStr', 'ep2d',...
    'SubjectFolderStr', '1..A_');
assignInputs(inStruct, varargin,...
    'compatibility', {'rawPath', 'path'});

% Get a list of subject folders in the input path
subFolders = get(fileData(inPath, 'Folders', 'on', 'Search', SubjectFolderStr), 'Path');



%% Delete Preprocessing Junk
for a = 1:length(subFolders)
    % Get a list of the current subject's functional folders
    currentScanFolders = get(fileData(subFolders{a}, 'Folders', 'on', 'Search', FunctionalFolderStr), 'Path');
    
    % Find the T1 anatomical scan folder
    currentAnatomicalFolder = get(fileData(subFolders{a}, 'Folders', 'on', 'Search', AnatomicalFolderStr), 'Path');
    
    % Delete anatomical import logs
    if exist([currentAnatomicalFolder{1} '/anatomical_import.txt'], 'file')
        delete([currentAnatomicalFolder{1} '/anatomical_import.txt']);
        delete([currentAnatomicalFolder{1} '/segments_import.txt']);
    end
    
    % Delete junk created in the functional folder during preprocessing
    for b = 1:length(currentScanFolders)
        if exist([currentScanFolders{b} '/IMG'], 'dir')
            rmdir([currentScanFolders{b} '/IMG'], 's');
            delete([currentScanFolders{b} '/' FunctionalFolderStr '*.*']);
        end
        if exist([currentScanFolders{b} '/Mean'], 'dir')
            rmdir([currentScanFolders{b} '/Mean'], 's');
        end
    end
end
