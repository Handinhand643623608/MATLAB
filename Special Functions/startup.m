%% STARTUP - Sets up the MATLAB environment for research work.

%% CHANGELOG
%   Written by Josh Grooms
%       20130611:   Updated to revert file structure to home computer settings. Added a help & reference section.
%       20130711:   Updated to use new function name for setting up the file structure. Added commenting.
%       20140703:   Rewrote this script to use the new PATHS class, which replaces the ancient file and path structure.
%       20140804:   Updated the working code directory across my computers, which received a much needed update today.
%                   Calling the working directory "svnSandbox" no longer makes sense; I haven't used SVN seriously in a
%                   very long time.
%       20141003:   Had to remove a SPM directory from the working path because it overloads the builtin nanmean
%                   function with either a completely broken version or one that (stupidly) uses global variables.
%       20141016:   Updated so that this procedure is universal between computers (no need for separate versions
%                   anymore). Also updated this script for compatibility with the Paths class rewrite.
%		20141113:	Removed automatic addition of Globals folder to MATLAB's working path altogether. These functions
%					just aren't used often enough to justify the headache and overhead they cause.
%		20141124:	Removed automatic addition of data directories to MATLAB's working path. These are almost always
%					specified using Path objects anyway nowadays, and this sometimes added data that I no longer want
%					added. Implemented automatic removal of code prototyping directories so code in here doesn't
%					accidentally get used.
%       20150114:   Implemented checks for the latest versions of Microsoft Visual Studio and Intel Parallel Studio.
%                   This is meant to warn users against running MEX functions I've developed if those programs are not
%                   installed.
%		20150330:	Updated to fix a new bug that was introduced after copying my deprecated function folder into my main
%					MATLAB code folder. The current version of the Paths class was being shadowed by an old version that
%					behaved very differently.
%		20150507:	Updated to prevent Deprecated and Prototyping folders from ever being added to MATLAB's search path. Even
%					adding all of the code folders and then removing those two was causing some problems.
%		20150612:	Added in support for MATLAB running on my Surface tablet.



%% Setup MATLAB Environment
% Determine the main code path based on the computer being used
switch (lower(getenv('COMPUTERNAME')))
    case {'desktop', 'surface'}
		main = 'C:/Users/Josh/Dropbox/MATLAB Code';
    case 'shella-bigboy1'
		main = 'C:/Users/jgrooms/Dropbox/MATLAB Code';
	otherwise
		main = '/home/jgrooms/Dropbox/MATLAB Code';
end

% Add all code directories to MATLAB's search path except for the prototyping & obsolete code folders
allpaths = genpath(main);
deprecated = genpath(fullfile(main, 'Deprecated'));
prototypes = genpath(fullfile(main, 'Prototyping'));
allpaths = strrep(allpaths, deprecated, '');
allpaths = strrep(allpaths, prototypes, '');
addpath(allpaths);

% Navigate to the main coding area
Paths.Main.NavigateTo();

% Check for the latest Microsoft Visual Studio installation
wassert(~isempty(getenv('VS120COMNTOOLS')),...
    'Microsoft Visual Studio 2013 not detected on this machine. Do not attempt to run MEX functions.');

% Check for the presence of a path to MKL DLLs for running optimized MEX functions
p = getenv('PATH');
wassert(~isempty(strfind(p, 'C:\Program Files (x86)\Intel\Composer XE 2015\redist\intel64\mkl')),...
    ['Intel MKL libraries were not found on the system PATH environment variable. Ensure that the path to these DLLs '...
     'is placed there. Otherwise, do not attempt to run MEX functions.']);

% Wipe the command window & variables
cle
