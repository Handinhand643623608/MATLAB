function wassert(expression, message, varargin)
% WASSERT - Generates a warning when a condition is violated.
%
%	WASSERT displays a warning message to the user when a certain condition fails. It functions exactly like the
%	MATLAB-native ASSERT, except that it produces warnings instead of exceptions that forcefully crash code execution.
%	This is useful in situations where it is prudent to alert the user of any failures, potential future problems, or
%	necessary additional steps that are encountered during processing but are not catastrophic to code execution.
%
%	This function is essentially a shortcut alternative to writing the following code:
%
%		if (~expression)
%			warning(message, varargin{:});
%		end
%	
%	SYNTAX:
%		wassert(expression)
%		wassert(expression, errmsg)
%		wassert(expression, errmsg, value1, value2,...)
%
%	INPUT:
%		expression:		BOOLEAN
%						A code expression that resolves to a single Boolean TRUE or FALSE. If this expression produces
%						the value FALSE, then the warning message is displayed. Otherwise, this function does nothing.
%
%	OPTIONAL INPUTS:
%		message:		STRING
%						A string containing the warning message to be printed in the MATLAB console. This string may
%						contain C-style escape or formatting characters to be filled in by the VALUE argument(s). See
%						the SPRINTF documentation for supported formatting characters. By default, this function
%						displays a generic warning message.
%						DEFAULT: 'Assertion failed.'
%
%		value:			ANYTHING
%						One or more values that will replace formatting characters in the MESSAGE string. Substitution
%						of values into this string occur sequentially.
%						DEFAULT: []
%
%	See also: ASSERT, ERROR, SPRINTF

%% CHANGELOG
%	Written by Josh Grooms on 20141217



%% Display a Warning in the Console
% Set a generic warning message if one isn't provided
if (nargin == 1); message = 'Assertion failed.'; end

% If the inputted expression is false, display the warning
if (~expression)
	warn(1, message, varargin{:});
end