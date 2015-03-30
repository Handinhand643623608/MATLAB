function pathList = contents(inPath)
%CONTENTS - Returns a list of paths to all folder contents.
%
%   SYNTAX:
%   pathList = contents(inPath)
%
%   OUTPUT:
%   pathList:       { STRINGS }
%                   A cell array of strings containing full paths (including file names and extensions) to any files
%                   that are inside of the input folder path. Folders within that directory are included in this list.
%
%   INPUTS:
%   inPath:         STRING
%                   The path to the folder that is to be used.

%% CHANGELOG
%   Written by Josh Grooms on 20140702



%% Get a List of Folder Contents
% Get a list of all folder contents
fileList = dir(inPath);
fileList = {fileList.name}';

% Remove the dots that the dir function includes
fileList(1:2) = [];

% Create full paths for all files
pathList = fullfile(inPath, fileList);