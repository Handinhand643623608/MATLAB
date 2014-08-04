function pathList = search(inPath, searchStr, varargin)
%SEARCH - Returns a list of full paths for specific files within a folder.
%
%   SYNTAX:
%   pathList = search(inPath, searchStr)
%   pathList = search(..., 'PropertyName', PropertyValue,...)
%
%   OUTPUT:
%   pathList:           { STRINGS }
%                       A cell array of strings containing full paths (including file names and extensions) to any files
%                       that match the input search parameter. This array will only be empty if the 'ErrorOnEmpty'
%                       parameter is manually turned off.
%
%   INPUTS:
%   inPath:             STRING
%                       The path to the folder that is to be searched.
%
%   searchStr:          STRING
%                       A string segment used to search for specific files in the directory. This parameter is compared
%                       against each of the file names in that directory, or possibly folder names if the folder
%                       extension input is used. Any file names that contain this signature will be included in the
%                       returned file path list. 
%
%                       Searching is accomplished using the REGEXPI native function with this parameter as the
%                       EXPRESSION argument. Any inputs that would be acceptable for REGEXPI will also be acceptable
%                       here, including metacharacters. Inputting an empty array for this argument results in no
%                       restrictions on file names.
%
%   OPTIONAL INPUTS:
%   'ErrorOnEmpty':     BOOLEAN
%                       A Boolean dictating whether or not to throw an error if no files matching the search criteria
%                       are found.
%                       DEFAULT: true
%
%   'Ext':              STRING
%                       A file extension to search for. The default value of this parameter is empty, which means that 
%                       the paths to all files matching the search parameter are returned regardless of what extension
%                       they possess. Specifying 'folder' for this parameter will return only paths to folders whose
%                       names contain the search term. 
%                       DEFAULT: [] 

%% CHANGELOG
%   Written by Josh Grooms on 20140702



%% Initialize
% Initialize a default settings structure
inStruct = struct(...
    'ErrorOnEmpty', true,...
    'Ext', []);
assignInputs(inStruct, varargin);

% Get a list of all files & folders from the selected path
allFiles = dir(inPath);
idsFolders = [allFiles.isdir];

% Remove folder paths unless explicitly called for
if strcmpi(Ext, 'folder')
    allFiles(~idsFolders) = [];
else
    allFiles(idsFolders) = [];
end

% Get a list of folder content names
allFileNames = {allFiles.name};



%% Search for Files & Folders
if ~isempty(allFileNames)
    
    % Search for specific file extensions, if called for 
    if ~isempty(Ext) && ~strcmpi(Ext, 'folder')
        idsExt = regexpi(allFileNames, [Ext '$']);
        idsExt = ~cellfun(@(x) isempty(x), idsExt);
        
        % If no file extensions are found, error out unless overridden
        if ~any(idsExt)
            if istrue(ErrorOnEmpty)
                error(['No files or folders with the extension %s were found in %s.\n'...
                       'Check to ensure that the data exists in this folder'],...
                       Ext,...
                       inPath);
            else
                pathList = {};
                return;
            end
        end
        
        % Eliminate all files without the proper extension
        allFileNames(~idsExt) = [];
    end
    
    % Search for a specific string within file names
    idsSearch = regexpi(allFileNames, ['.*' searchStr '.*']);
    idsSearch = ~cellfun(@(x) isempty(x), idsSearch);

    % If no files matching the search parameter are found, error out unless overridden
    if ~any(idsSearch)
        if istrue(ErrorOnEmpty)
            error(['No files or folders with the signature %s were found in %s.\n'...
                   'Check to ensure that the data exists in this folder'],...
                   searchStr,...
                   inPath);
        else
            pathList = {};
            return;
        end
    end
    
    % Eliminate all files whose names don't match the search parameter
    allFileNames(~idsSearch) = [];
    
    % Return a list of files matching the search term & extension, if called for
    pathList = fullfile(inPath, allFileNames);
    pathList = pathList';
    
elseif istrue(ErrorOnEmpty)
    
    % Error out if no files/folders exist in the input directory
    error('No files or folders were found inside the directory %s', inPath);
    
end