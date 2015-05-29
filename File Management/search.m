% SEARCH - Searches the contents of a directory for specific files or folders.
%
%   SYNTAX:
%		plist = search(p, query)
%
%   OUTPUT:
%		plist:		{ STRINGS }
%					A cell array of path strings pointing to any files and folders that match the inputted query.
%
%   INPUTS:
%		p:			STRING
%					A path string pointing to the folder whose contents are to be searched.
%
%   	query:		STRING
%					A string segment used to search for specific contents within the directory P. This parameter is compared
%					against each of the file or folder names in that directory. Any names that contain this signature will be
%					included in the returned path list.
%
%					Searching is accomplished using the native function REGEXPI with this parameter as the EXPRESSION
%					argument. Any inputs that would be acceptable for REGEXPI will also be acceptable here, including
%					metacharacters.
%
%	See also: CONTENTS, DIR, FILE, REGEXPI, PATH, WHERE

%% CHANGELOG
%   Written by Josh Grooms on 20140929
%		20150510:	Completely rewrote and streamlined this function to get rid of a bunch of extraneous functionality. Also
%					changed its behavior so that it never throws errors but instead generates warnings when searches come up
%					empty.
%		20150518:	Replaced an inconvenient call to a static Path class method. Using that method introduced an unnecessary
%					dependency in an otherwise standalone function.



%% FUNCTION DEFINITION
function plist = search(p, query)
	
	allcontents = dir(p);
	allcontents = { allcontents.name }';
	allcontents(1:2) = [];
	
	idsMatch = regexpi(allcontents, query);
	idsMatch = ~cellfun(@isempty, idsMatch);
	
	if ~any(idsMatch)
		warning(['No files for folders containing %s were found in %s.\n'...
				 'Check to ensure that the file exists within this folder'],...
				 query,...
				 p);
		plist = {};
		return;
	end
	
	plist = fullfile(p, allcontents(idsMatch));
	plist = cellfun(@(x) strrep(x, '\', '/'), plist, 'UniformOutput', false);	
	
end