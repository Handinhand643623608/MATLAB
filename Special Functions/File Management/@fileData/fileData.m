classdef fileData < dirData
%FILEDATA Creates a file object based on an input path.
%   FILEDATA parses a given input path and creates a fileData object containing information about all files in that
%   path. When called from FOLDERDATA, this object is instantiated repeatedly throughout a folder hierarchy in order to
%   accrue all file information under the given path. On its own, however, this function only searches the input
%   directory.
%
%   SYNTAX:
%   fileObj = fileData(path)
%   fileObj = fileData(path, 'PropertyName', PropertyValue...)
%
%   OUTPUT:
%   fileObj:        FILEOBJ or FILEOBJ ARRAY
%                   The file object array containing information on all non-folder files within the specified path.
%
%   INPUTS:
%   path:           STRING
%                   The path string for which all file data will be accumulated. 
%
%   OPTIONAL INPUTS:
%   'Ext':          STRING
%                   The desired extension of files to be returned in the file object array. Files in the input path
%                   without this extension will not be returned.
%                   DEFAULT: any extension
%
%   'ErrorOnEmpty:  BOOLEAN
%                   A Boolean indicating whether or not errors are thrown if files cannot be found. This applies to
%                   searches for both file extensions and strings that are part of folder or file names. If set to
%                   false, no error is thrown when the desired data cannot be found. Instead, an empty file data object
%                   is returned.
%                   DEFAULT: true
%
%   'Search':       STRING
%                   A string to be searched for within the object array's file names. Any files whose name does not
%                   contain this string will not be returned in the output.
%                   DEFAULT: any file name

%% CHANGELOG
%   Written by Josh Grooms on 20130201
%       20130202:   Updated aggregateInfo method to protected status 
%       20130221:   Added 'compatibility' section to assignInputs for alternate variable names. Also wrote an overload 
%                   for "get" to include sorting options & neater presentation.
%       20130320:   Bug fix for function only returning one file object.
%       20130611:   Expanded help & reference section. Updated to allow for searches for strings and file extensions
%                   directly from object array instantiation.
%       20130614:   Added functionality for getting folders instead of files. This object has now completely absorbed
%                   the working functionality of "folderData"
%       20140623:   Implemented an input that dictates whether or not errors are thrown if a search for a particular
%                   extension or file name string turns up nothing. The default is to error out of the program.

%% DEPENDENCIES
%   
%   @dirData
%
%   assignInputs
%   istrue

%% TODOS
% Immediate Todos


    
    %% Constructor Method
    methods
        function fileObj = fileData(inPath, varargin)
            %FILEDATA Constructs the file object using the input parameters.
            if nargin ~= 0
                fileObj = aggregateInfo(fileObj, inPath, varargin{:});
            end           
        end       
    end
       
    
    
    %% Public Methods
    methods 
        % Overload "get" for the object properties
        fileNames = get(fileObj, propName, varargin)
        fileObj = search(fileObj, varargin)
    end
    
    
    
    %% Protected Methods
    methods (Access = protected)        
        fileObj = aggregateInfo(fileObj, varargin)
    end
    
    
end
        
        