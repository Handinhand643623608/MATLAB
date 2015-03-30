function pathList = Search(myPaths, folder, searchStr, varargin)
%SEARCH - Returns a list of full paths for specific files within a folder.
%
%   SYNTAX:
%   pathList = Search(myPaths, folder, searchStr)
%   pathList = Search(..., 'PropertyName', PropertyValue)
%   
%   OUTPUT:
%   filePaths:          { STRINGS }
%                       A cell array of strings containing full paths (including file names and extensions) to any files
%                       that match the input search parameter. This array will only be empty if the 'ErrorOnEmpty'
%                       parameter is manually turned off.
%
%   INPUTS:
%   myPaths:            PATHS
%                       A PATHS object containing a list of important personal computer paths.
%
%   folder:             STRING
%                       One of the property names of the PATHS object, indicating which directory will be used for this
%                       function. This parameter is case sensitive.
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
%   Written by Josh Grooms on 20140630
%       20140702:   Moved the core functionality of this method to a generic function that handles path strings. This
%                   method is now just a wrapper for that function. 


%% Search the Requested Folder
% This function just wraps the generic version for the PATHS class
pathList = search(get(myPaths, folder), searchStr, varargin{:});