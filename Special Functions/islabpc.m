% ISLABPC - Determines whether or not this MATLAB instance is running on my lab computer.
%
%	SYNTAX
%		b = islabpc()
%
%	OUTPUT:
%		b:		BOOLEAN
%				A Boolean true if this function is invoked from a MATLAB instance running on my lab PC, or false otherwise.

%% CHANGELOG
%	Written by Josh Grooms on 20150210



%% FUNCTION DEFINITION
function b = islabpc()
	b = false;
	pcname = getenv('COMPUTERNAME');
	if strcmpi(pcname, 'SHELLA-BIGBOY1'); b = true; end
end