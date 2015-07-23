% CONTENTS - Generates a list of path strings pointing to all contents of a directory and, optionally, its subdirectories.
%
%   SYNTAX:
%		plist = contents(p)
%		plist = contents(p, recursive)
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
%	OPTIONAL INPUTS:
%		recursive:	BOOLEAN
%					A Boolean indicating whether or not to list the contents of any subdirectories found under P.
%					DEFAULT: false
%
%	See also: DIR, FILE, PATH, SEARCH, WHERE

%% CHANGELOG
%   Written by Josh Grooms on 20140702
%		20150510:	Improved the documentation for this function. Also implemented automatic formatting of path string
%					separator characters so that they're always uniform between Linux and Windows systems.
%		20150528:	Replaced an inconvenient call to a static String class method. Using that method introduced an
%					unnecessary dependency in an otherwise standalone function.
%		20150616:	Implemented optional recursion to list the contents of subdirectories for the inputted path.



%% FUNCTION DEFINITION
function plist = contents(p, recursive)
	
	% Default to a non-recursive content listing
	if (nargin == 1 || isempty(recursive)); recursive = false; end
	
	% Get a list of all folder contents & remove the two uppermost directories
	fileList = dir(p);
	fileList(1:2) = [];
	isDir = [fileList.isdir];
	fileList = {fileList.name}';
	
	if recursive
		
		% Recursively gather all of the contents of the directory & its subdirectories
		plist = {};
		for a = 1:length(fileList)
			if isDir(a)
				ctfolder = [p '/' fileList{a}];
				ctcontents = contents(ctfolder, true);
				plist = cat(1, plist, ctfolder, ctcontents{:});
			else
				plist = cat(1, plist, [p '/' fileList{a}]);
			end			
		end
		
	else
		plist = fullfile(p, fileList);
	end
	
	% Standardize path string separator characters
	plist = cellfun(@(x) strrep(x, '\', '/'), plist, 'UniformOutput', false);
	
end