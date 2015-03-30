function folderObj = aggregateInfo(folderObj, inPath, varargin)
%AGGREGATEINFO Aggregates file and folder names and attributes into a folder object.
%   AGGREGATEINFO is a class-specific method for FOLDERDATA objects and is not intended for general
%   use.
% 
%   Written by Josh Grooms on 20130201
%       20130318:  Bug fixes
%       20130614:  Major overhaul to functionality & bug fixes so that function behaves similarly to
%                  "fileData" objects. Added ability to search for folder names.

% TODO: Implement folder size determination


%% Initialize Defaults & Settings
inStruct = struct(...
    'includeFiles', false,...
    'recursiveScan', false,...
    'searchStr', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'includeFiles', 'filedata', 'files', [];...
                      'recursiveScan', 'recursive', 'multilevel', 'subfolders';...
                      'searchStr', 'search', 'string', 'searchfor'});
inPath = regexprep(inPath, '(\s$|\\$)', '');

% Get properties of the uppermost directory
files = dir(inPath);
dateModified = datestr(files(1).datenum, 'yyyymmddTHHMMSS');
[~, folderName, ~] = fileparts(inPath);

% Assign currently known values
folderObj.DateModified = dateModified;
folderObj.Name = folderName;
folderObj.Path = inPath;

% Get rid of the dots that "dir" includes
files(1:2) = [];

% Find which are files & folders
idsFolders = cat(1, files.isdir);


%% Compile a List of Files & Their Details
% Generate file objects
if includeFiles || strcmpi(includeFiles, 'on')
    folderObj.Files = fileData('inPath', inPath);
end


%% Compile a List of Folders & Their Details
% Get the names, paths, & dates of creation
if any(idsFolders)
    % Get the names of all "dir" outputs
    folderNames = {files.name}';
    
    % If a search is called for, get the indices of matches
    if ~isempty(searchStr)
        notFlag = false;
        if strcmp(searchStr(1), '~')
            notFlag = true;
            searchStr(1) = [];
        end
        idsSearch = regexpi(folderNames, ['.*' searchStr '.*']);
        if notFlag
            idsSearch = cellfun(@(x) isempty(x), idsSearch);
        else
            idsSearch = ~cellfun(@(x) isempty(x), idsSearch);
        end
        idsFolders = idsFolders & idsSearch;
    end
    
    % Get the "dir" properties
    folderNames = folderNames(idsFolders);
    folderDatesModified = {files(idsFolders).datenum}';
    folderDatesModified = cellfun(@(x) datestr(x, 'yyyymmddTHHMMSS'), folderDatesModified, 'UniformOutput', false);
    folderPaths = regexprep(folderNames, '^', regexptranslate('escape', [inPath '\']), 'emptymatch');
   
    % If scanning of subfolders is called for, perform that
    if (recursiveScan || strcmpi(recursiveScan, 'on')) && ~isempty(folderNames)
        % If recursively scanning through folders, create folder objects out of each subdirectory
        tempFolderObjs(length(folderNames)) = folderData;
        for i = 1:length(folderNames)
            tempFolderObjs(i) = folderData(folderPaths{i}, 'includeFiles', includeFiles, 'recursiveScan', recursiveScan);
        end
    else
        % Otherwise, just get information about folders in the current directory
        tempFolderObjs(length(folderNames)) = folderData;
        for i = 1:length(folderNames)
            tempFolderObjs(i).DateModified = folderDatesModified{i};
            tempFolderObjs(i).Name = folderNames{i};
            tempFolderObjs(i).Path = folderPaths{i};
        end
    end
        
    % Assign the folder objects to the output
    folderObj.Folders = tempFolderObjs;
end