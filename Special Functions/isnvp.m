% ISNVP - Checks whether or not a cell array could consist of name/value pairs.
%
%	ISNVP tries to determine if the inputted cell array could be a vector of name/value pairs (NVPs). NVPs are frequently
%	employed as a convenience in functions that would otherwise have long lists of optional input arguments. 
%
%	NVP presence is checked in two ways. First, the inputted cell array C must be a vector; multidimensional cell arrays
%	automatically fail the test. Second, every other element of the cell vector (starting with the first) must contain a
%	string. If the inputted cell passes these tests, then it is possible that it is an NVP list, and this function returns a
%	Boolean true. Bear in mind, however, that this test is not conclusive and that any cell vector of strings will pass it. 
%
%	SYNTAX:
%		b = isnvp(c)
%
%	OUTPUT:
%		b:		BOOLEAN
%				A Boolean true if C is a vector and contains a string at every second element. If not, false is returned.
%
%	INPUT:
%		c:		CELL
%				A cell vector of values to be tested.

%% CHANGELOG
%	Written by Josh Grooms on 20150225
%		20150529:	Implemented a new check for the length of a cell array being a multiple of two.



%% FUNCTION DEFINITION
function b = isnvp(c)
	
	if ~isvector(c);			b = false; return; end
	if mod(length(c), 2) ~= 0;	b = false; return; end
	nvpchk = cellfun(@ischar, c(1:2:end));
	b = all(nvpchk);
	
end