% CLE - Clear and close absolutely everything from the base workspace.
%
%   This function clears all variables and classes from the base workspace. It also dismisses all open figure windows and any
%   text that appears in the command window. In short, it executes the following commands:
%       clear all
%       clear classes
%       close all
%       clc
%
%   SYNTAX:
%   cle
%
%	See also: cla, clc, clf

%% CHANGELOG
%   Written by Josh Grooms on 20131003
%		20150406:	Updated the documentation and its placement to conform with more recent standards.



%% FUNCTION DEFINITION
function cle
	
	evalStr = 'close all; clear all; clear classes; clc';
	evalin('base', evalStr);
	
end
