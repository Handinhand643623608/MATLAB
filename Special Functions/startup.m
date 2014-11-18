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


%% Setup MATLAB Environment
% Add the path to the main code storage area
switch (lower(getenv('COMPUTERNAME')))
    case 'desktop'
        addpath(genpath('C:/Users/Josh/Dropbox/MATLAB Code/'));
    case 'shella-bigboy1'
        addpath(genpath('C:/Users/jgrooms/Dropbox/MATLAB Code/'));
    otherwise
        addpath(genpath('/home/jgrooms/Dropbox/MATLAB Code'));
end

% Navigate to the main coding area
Paths.Main.NavigateTo();

% Add data paths to MATLAB's working directories
addpath(genpath(Paths.Data));

% Wipe the command window
clc
