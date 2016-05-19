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
%       20150428:   Updated to use the newer input assignment system and to utilize Path objects.



%% FUNCTION DEFINITION
function CleanRawFolders(inPath, varargin)

    function Defaults
        AnatomicalFolderStr = 't1_MPRAGE';
        FunctionalFolderStr = 'ep2d';
        SubjectFolderStr = '1..A_';
    end
    assign(@Defaults, varargin);

    % Get a list of subject folders in the input path
    subFolders = inPath.FolderSearch(SubjectFolderStr);

    for a = 1:length(subFolders)
        % Get a list of the current subject's functional folders
        ctScanFolders = subFolders(a).FolderSearch(FunctionalFolderStr);

        % Find the T1 anatomical scan folder
        ctAnatomicalFolder = subFolders(a).FolderSearch(AnatomicalFolderStr);

        % Delete anatomical import logs
        for b = 1:length(ctAnatomicalFolder)
            if exist([ctAnatomicalFolder(b).ToString() '/anatomical_import.txt'], 'file')
                delete([ctAnatomicalFolder(b).ToString() '/anatomical_import.txt']);
                delete([ctAnatomicalFolder(b).ToString() '/segments_import.txt']);
            end
        end

        % Delete junk created in the functional folder during preprocessing
        for b = 1:length(ctScanFolders)
            if exist([ctScanFolders(b).ToString() '/IMG'], 'dir')
                rmdir([ctScanFolders(b).ToString() '/IMG'], 's');
                delete([ctScanFolders(b).ToString() '/' FunctionalFolderStr '*.*']);
            end
            if exist([ctScanFolders(b).ToString() '/Mean'], 'dir')
                rmdir([ctScanFolders(b).ToString() '/Mean'], 's');
            end
        end
    end
end