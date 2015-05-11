% CONTENTS - Generates a list of path strings pointing to all contents of a folder.
%
%   SYNTAX:
%		plist = contents(p)
%
%   OUTPUT:
%		plist:		{ STRINGS }
%					A cell array of strings containing full paths (including file names and extensions) to any files that
%					are inside of the input folder path. Folders within that directory are also included in this list.
%
%   INPUTS:
%		p:			STRING
%					A path string pointing to the folder whose contents are to be listed.
%
%	See also: DIR, FILE, PATH, SEARCH, WHERE

%% CHANGELOG
%   Written by Josh Grooms on 20140702
%		20150510:	Improved the documentation for this function. Also implemented automatic formatting of path string
%					separator characters so that they're always uniform between Linux and Windows systems.



%% FUNCTION DEFINITION
function plist = contents(p)
	
	% Get a list of all folder contents
	fileList = dir(p);
	fileList = {fileList.name}';

	% Remove the dots that the dir function includes
	fileList(1:2) = [];

	% Create full paths for all files
	plist = String.FormatSeparators(fullfile(p, fileList));
	
end