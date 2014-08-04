function pathList = Contents(myPaths, folder)
%CONTENTS - Returns a list paths to all folder contents.
%
%   SYNTAX:
%   pathList = Contents(Paths, folder)
%
%   OUTPUT:
%   pathList:       { STRINGS }
%                   A cell array of strings containing full paths (including file names and extensions) to any files
%                   that are inside of the requested folder path. Folders within that directory are included in this
%                   list.
%
%   INPUTS:
%   myPaths:        PATHS
%                   A PATHS object containing a list of important personal computer paths.
%
%   folder:         STRING
%                   One of the property names of the PATHS object, indicating which directory will be used for this
%                   function. This parameter is case sensitive.

%% CHANGELOG
%   Written by Josh Grooms on 20140702


%% Get a List of Folder Contents
% This function just wraps the generic version for the PATHS class
pathList = contents(get(myPaths, folder));