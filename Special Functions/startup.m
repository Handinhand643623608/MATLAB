%%STARTUP Sets up the MATLAB environment for research work.

%% CHANGELOG
%   Written by Josh Grooms
%       20130611:   Updated to revert file structure to home computer settings. Added a help & reference section.
%       20130711:   Updated to use new function name for setting up the file structure. Added commenting.
%       20140703:   Rewrote this script to use the new PATHS class, which replaces the ancient file and path structure.



%% Setup MATLAB Environment
% Add the path to the main code storage area
addpath(genpath('C:\Users\Josh\Dropbox\svnSandbox\'))

% Navigate to the main coding area
CD(Paths, 'Main');

% Add data paths to MATLAB's working directories
addpath(genpath(get(Paths, 'DataObjects')));
addpath(genpath(get(Paths, 'Globals')));

% Wipe the command window
clc
