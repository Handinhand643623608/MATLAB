function filenames = fileNames(varargin)
%FILENAMES Produces a cell array of file names given a path and other
%   optional variables). The file names output also contains the full path 
%   of the files of interest.
% 
%   Uses the new input system. All inputs are optional. Input name/value 
%   pairs in any order according to the following system:
% 
%   SYNTAX:
%   filenames = fileNames('propertyName', propertyValue,...)
% 
%   PROPERTY NAMES:
%   searchPath:     A path to the folder containing the file names of
%                   interest
%                   DEFAULT: current working directory (pwd)
% 
%   searchStr:      A string of all or part of the file names of interest 
%                   EXAMPLES: 'part*', '*temp', '*data*', 'corrData', etc)
%                   DEFAULT: empty array (any file name)
% 
%   fileExt:        A string of the file extension ('.' inclusion doesn't
%                   matter)
%                   EXAMPLES: '.mat', 'exe', 'dir' (for folder names only)
%                   DEFAULT: empty array (any file extension)
% 
%   sort:           A string of either 'alphabetical' or 'date' indicating
%                   to sort output names alphabetically or by date of
%                   creation/modification.
%                   DEFAULT: 'alphabetical'
% 
%   sortDirection:  Direction of the sort, either 'ascend' or 'descend'
%                   in order to sort from A-->Z and Earlier-->Later, or
%                   reverse, respectively.
%                   DEFAULT: 'ascend' 
% 
%   Written by Josh Grooms on 20120618
%       20130107:   Re-written to allow more flexible input more options
%       20130111:   Updated to new file naming scheme & moved to special functions folder
%       20130112:   Updated to work with improved assignInputs
%       20130113:   Bug fix in the formatting and assigning of input parameters
%       20130120:   Updated help section


%% Initialize
% Default settings
inStruct = struct(...
    'searchPath', pwd,...
    'searchStr', '*',...
    'fileExt', '*',...
    'sortBy', 'alphabetical',...
    'sortDirection', 'ascend');
assignInputs(inStruct, varargin,...
    {'searchPath', 'searchStr', 'fileExt'}, 'regexprep(varPlaceholder, ''(^\.|\\$)'', '''')');


%% Get the File Names from the Directory
% Query the search path for the files or folders of interest
if strcmpi(fileExt, 'dir') || isempty(fileExt)
    tempDir = dir([searchPath '\' searchStr]);
    tempDir(1:2) = [];
else
    tempDir = dir([searchPath '\' searchStr '.' fileExt]);
end

% If looking for folders, get rid of all other files
if strcmpi(fileExt, 'dir')
    idsDir = [tempDir.isdir];
    tempDir(~idsDir) = [];
end

% Get the filenames
filenames = {tempDir.name}';

% Sort the filenames
switch sortBy
    % Ascending/descending alphabetical
    case 'alphabetical'
        [NU idsSorted] = sort(upper(filenames));
        if strcmpi(sortDirection, 'descend')
            idsSorted = flipdim(idsSorted, 1);
        end        
    
    % Ascending/descending by date modified
    case 'date'
        [NU idsSorted] = sort([tempDir.datenum]', sortDirection);
end    

% Apply the sorting permutation to the filenames & append to the file path
filenames = filenames(idsSorted);
filenames = regexprep(filenames, '^', regexptranslate('escape', [searchPath '\']), 'emptymatch');