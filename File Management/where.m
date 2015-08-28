% WHERE - Returns the path to the directory containing a function or file without the file name included.
%
%   This function is essentially a wrapper to the MATLAB-native function WHICH. The WHICH function searches MATLAB's working
%   path lists to find files and functions whose names match the inputted string argument, returning the full path to the
%   file if it exists.
%
%   WHERE does precisely the same thing, and even calls WHICH to accomplish this, but before the path string is outputted the
%   name and extension of the file are removed from the end. Thus, the path that is returned points to the directory that
%   contains the file instead of pointing to the file itself.
%
%   SYNTAX:
%       p = where(fileName)
%
%   OUTPUT:
%       p:              STRING
%                       A path string pointing to the folder where the inputted file exists on the hard drive. If the file
%                       name being searched for does not exist or is not in a directory that is included in MATLAB's working
%                       path list, then this will be an empty string. Otherwise, it will be the full path to the folder
%                       without the file name or extension included at the end.
%
%   INPUT:
%        fileName:      STRING
%                       The name of the file or function to be located. Including the file's extension is optional. Any given
%                       name that is inputted here must refer to a file or function that is on MATLAB's working path in order
%                       for it to be successfully found. Otherwise, the search will return an empty string even if the
%                       desired file does indeed exist.
%
%   See also: CONTENTS, DIR, FILE, PATH, SEARCHDIR, WHICH

%% CHANGELOG
%   Written by Josh Grooms on 20140725
%		20150510:	Improved the documentation for this function.



%% FUNCTION DEFINITION
function filePath = where(fileName)
	
	% Call WHICH to do the heavy lifting of finding the file, then just remove the file name from the end
	[filePath, ~, ~] = fileparts(which(fileName));
	
end