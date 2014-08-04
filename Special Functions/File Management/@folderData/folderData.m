classdef folderData < dirData
%FOLDERDATA Creates a folder object based from an input path.
%   FOLDERDATA performs one of two functions based on used input. First, it can parse a given
%   input path and create a folderData object containing information about all files and folders
%   within and beneath that path. Using this functionality, this object is similar to the output
%   of the Special Function FILENAMES, but much more extensive. Second, it can create a folder
%   hierarchy in any given path based on specific input parameters. This functionality is
%   similar to the behavior of the Special Function CREATENESTEDFOLDERS.
%     
%   WARNING: This code is still under core development and is not yet intended for serious use.
%     
%   Syntax:
%   folderObj = folderData('propertyName', propertyValue,...)
% 
%   Outputs:
%   folderObj:
% 
%   Inputs:
%   inPath:
% 
%   ('getFiles'):
% 
%   ('recursiveScan'):
% 
%   ('firstLevel'):
% 
%   ('secondLevel'):
%     
%   Written by Josh Grooms on 20130201
%       20130202:   Updated aggregateInfo method to protected status
%       20130318:   Bug fixes to make function operational. Improvements to variable name
%                   compatibility.

%   TODO: Implement folder hierarchy creation

    
    properties
        Files               % A file object array containing file information
        Folders             % A folder object array containing files & folders of any subdirectories
    end
    
    methods
        %% Constructor Function
        function folderObj = folderData(inPath, varargin)
            %FOLDERDATA Constructs the folder object using the various input parameters.                           
            if nargin ~= 0         
                aggregateInfo(folderObj, inPath, varargin{:});
            end
        end
    end
    
    methods (Access = protected)
        %% Protected Methods
        % Aggregate files & folders beneath the input path
        folderObj = aggregateInfo(folderObj, inPath, varargin)
       
        
        %% Public Methods
%         objHandle = createFirstLevel(objHandle, firstLevel)
        
%         objHandle = createSecondLevel(objHandle, firstLevel)
    end
end
    
        
        