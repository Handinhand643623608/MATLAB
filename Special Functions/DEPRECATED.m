% DEPRECATED - Marks a function or class method as deprecated and displays a warning message to the user that called it.
%
%	DEPRECATED warns users about code that is no longer being maintained or has been replaced with something else that offers
%	better functionality. 
%
%	SYNTAX:
%		DEPRECATED
%		DEPRECATED alt
%
%	OPTIONAL INPUT:
%		alt:		STRING
%					The full name of an alternative function or class method that replaces the functionality of the
%					deprecated code. If this argument is not provided or left empty, no alternatives are suggested.
%
%	See also: WARN, WARNING, WASSERT

%% CHANGELOG
%	Written by Josh Grooms on 201502012



%% FUNCTION DEFINITION
function DEPRECATED(alt)
	fstack = dbstack(1);
	if (nargin == 0 || isempty(alt))
		warn(1, 'The function ''%s'' has been deprecated and will be removed in the future.', fstack(1).name);
	else
		warn(1, ['The function ''%s'' has been deprecated and will be removed in the future. ' ...
			'Use the function ''%s'' instead.'], fstack.name, alt);
	end
end