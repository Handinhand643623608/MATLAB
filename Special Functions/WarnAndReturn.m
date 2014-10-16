function WarnAndReturn(message, varargin)
% WARNANDRETURN - Displays a warning message in the console and forces the calling function to return.
%
%   SYNTAX:
%   WarnAndReturn(message)
%   WarnAndReturn(message, var1, var2,..., varN)
%
%   INPUT:
%   message:    STRING
%               The message string that will be displayed in the MATLAB command window to the user.
%
%   OPTIONAL INPUTS:
%   var:        ANYTHING
%               Any variable or list of variables whose values will be formatted into the message string. This argument
%               can be of any type and length, as long as it is correctly matched with the formatting characters found
%               in the message string. For details on acceptable escape sequences, see the native SPRINTF documentation.
%
%   See also: WARNING, ERROR, SPRINTF

%% CHANGELOG
%   Written by Josh Grooms on 20141015



%% Produce the Warning & Return Command
% Input error check
assert(nargin >= 1, 'Warnings must contain a message.');
assert(ischar(message), 'Warning message must be a string.');

% Display the warning & force the calling function to return
warning(message, varargin{:});
evalin('caller', 'eval(''return'')');

