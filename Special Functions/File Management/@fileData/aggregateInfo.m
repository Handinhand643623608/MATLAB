function fileObj = aggregateInfo(fileObj, inPath, varargin)
%AGGREGATEINFO Aggregates file names and attributes into a file object.
%   AGGREGATEINFO is a class-specific method for FILEDATA objects and is not intended for general use.



%% CHANGELOG
%   Written by Josh Grooms on 20130201
%       20130611:   Set default file path to the current working directory. Implemented options to search for strings & 
%                   extensions in file names. Cleaned up some unnecessary code.
%       20130614:   Added functionality for getting folders instead of files. This object has now completely absorbed 
%                   the working functionality of "folderData".
%       20130628:   Bug fix for path separators on Linux systems
%       20130707:   Another bug fix for path separators on Linux systems
%       20140620:   Updated analyzing the "getFolders" input flag to use "istrue" so that it's more robust to variations
%                   on its value that mean the same thing. Implemented a more descriptive error message that gets thrown
%                   when no files or folders are found in the inputted directory, with or without a search string.
%       20140623:   Implemented an input that dictates whether or not errors are thrown if a search for a particular
%                   extension or string turns up nothing. The default is to error out of the program. 



%% Initialize
% Initialize a defaults structure & settings
inStruct = struct(...
    'Ext', [],...
    'ErrorOnEmpty', true,...
    'GetFolders', false,...
    'SearchStr', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'Ext', 'extension', [], [];...
                      'GetFolders', 'folders', 'searchFolders', [];...
                      'SearchStr', 'search', 'string', 'searchfor'});
inPath = regexprep(inPath, '(\s$|\\$|/$)', '');

% Get a list of all files & folders
files = dir(inPath);
files(1:2) = [];

% Find file entries (not folders)
if istrue(GetFolders)
    idsFiles = cat(1, files.isdir);        
else
    idsFiles = ~cat(1, files.isdir);
end    



%% Aggregate a List of File Names, Sizes, Dates Modified, & Full Paths
if any(idsFiles)
    % Get the names of all "dir" outputs
    fileNames = {files.name}';
    
    % If a particular extension is desired, get the indices of matches
    if ~isempty(Ext) && ~istrue(GetFolders)
        idsExt = regexpi(fileNames, [Ext '$']);
        idsExt = ~cellfun(@(x) isempty(x), idsExt);
        
        % If no files are found, either error out or return an empty file object, depending on user input
        if ~any(idsExt) 
            if istrue(ErrorOnEmpty)
                error(['No files or folders with the extension %s were found in %s.\n'...
                       'Check to ensure that the data exists in this folder'],...
                       Ext,...
                       inPath);
            else
                fileObj = fileData;
                return;
            end
        end
        
        idsFiles = idsFiles & idsExt;
    end
    
    % If a search is called for, get the indices of matches
    if ~isempty(SearchStr)
        notFlag = false;
        if strcmp(SearchStr(1), '~')
            notFlag = true;
            SearchStr(1) = [];
        end
        idsSearch = regexpi(fileNames, ['.*' SearchStr '.*']);
        if notFlag
            idsSearch = cellfun(@(x) isempty(x), idsSearch);
        else
            idsSearch = ~cellfun(@(x) isempty(x), idsSearch);
        end
        
        % If no files are found, either error out or return an empty file object, depending on user input
        if ~any(idsSearch)
            if istrue(ErrorOnEmpty)
                error(['No files or folders with the signature %s were found in %s.\n'...
                      'Check to ensure that the data exists in this folder'],...
                      SearchStr,...
                      inPath);
            else
                fileObj = fileData;
                return;
            end
        end
        
        idsFiles = idsFiles & idsSearch;
    end
    
    % Get the "dir" properties & transfer to the file object
    fileNames = fileNames(idsFiles);    
    fileDatesModified = {files(idsFiles).datenum}';
    filePaths = regexprep(fileNames, '^', regexptranslate('escape', [inPath '/']), 'emptymatch');
    fileSizes = cat(1, files(idsFiles).bytes);

    % Pre-allocate the output object array
    tempFileObj(length(fileNames)) = fileData;

    % Assign the outputs
    for i = 1:length(fileNames)
        tempFileObj(i).DateModified = fileDatesModified{i};
        tempFileObj(i).Name = fileNames{i};
        tempFileObj(i).Path = filePaths{i};
        tempFileObj(i).Size = fileSizes(i);
    end
    fileObj = tempFileObj;
else
    error('No files or folders were found inside the directory %s', inPath);
end