% String - A collection of utility functions that specifically operate on or produce strings.
%
%	String Methods:
%		ArraySize			- Converts an array size vector into a formatted string representation.
%		Boolean				- Converts a Boolean value into a standardized string representation.
%		Deblank				- Removes or replaces all white space found within a string.
%		FormatSeparators	- Replaces any alternative path separators in a string with the universal '/' character.
%		RemoveLeading		- Removes a specified character from the beginning of a string.
%		RemoveSurrounding	- Removes a specified character from the beginning and end of a string.
%		RemoveTrailing		- Removes a specified character from the end of a string.

%% CHANGELOG
%	Written by Josh Grooms on 20150212
%		20150430:	Implemented a new method called Deblank to remove spaces within a string.
%		20150507:	Overhauled the class documentation to summarize all of the properties and methods that are available.



%% CLASS DEFINITION 
classdef String < Entity


	
	%% UTILTIES
	methods (Static)
		
		function s = ArraySize(sz)
		% ARRAYSIZE - Converts a size array into a standardized string representation.
			s = ['(' regexprep(num2str(sz), '\s+', ' x ') ')'];
		end
		function s = Boolean(b)
		% BOOLEAN - Converts a Boolean value into a standardized string representation.
			if b;	s = 'true';
			else	s = 'false'; end
		end
		function s = Deblank(s, c)
		% DEBLANK - Removes or replaces spaces found within a string.
		%
		%	SYNTAX:
		%		s = String.Deblank(s)
		%		s = String.Deblank(s, c)
		%
		%	OUTPUT:
		%		s:	STRING or { STRINGS }
		%			A deblanked string or cell array of strings, depending on the input S. Any spaces that were present in S
		%			will be removed or replaced by the character(s) found in C.
		%
		%	INPUT:
		%		s:	STRING or { STRINGS }
		%			A string or cell array of strings for which spaces should be removed or replaced by the value in C.
		%
		%	OPTIONAL INPUT:
		%		c:	CHAR or STRING
		%			A single character or string of characters that will replace any spaces that are found in S.
		
			if (nargin == 1); c = ''; end
			if (isempty(c)); c = ''; end
			if (iscell(s))
				s = cellfun(@(x) String.Deblank(x, c), s, 'UniformOutput', false);
			else
				s = strrep(s, ' ', c);
			end
		end
		function s = FormatSeparators(s)
		% FORMATSEPARATORS - Replaces any alternative path separators in a string with the universal '/' character.
			s = strrep(s, '\', '/');
		end
		function s = RemoveLeading(s, c)
		% REMOVELEADING - Removes a character from the beginning of a string.
			if ~iscell(c); c = { c }; end			
			if iscell(s)
				s = cellfun(@(x) String.RemoveLeading(x, c), s, 'UniformOutput', false);
			else
				while ismember(s(1), c)
					s(1) = [];
				end
			end
		end
		function s = RemoveSurrounding(s, c)
		% REMOVESURROUNDING - Removes a character from the beginning and end of a string.
			if ~iscell(c); c = { c }; end
			s = String.RemoveLeading(s, c);
			s = String.RemoveTrailing(s, c);
		end
		function s = RemoveTrailing(s, c)
		% REMOVETRAILING - Removes a character from the end of a string.
			if ~iscell(c); c = { c }; end
			if iscell(s)
				s = cellfun(@(x) String.RemoveTrailing(x, c), s, 'UniformOutput', false);
			else
				while ismember(s(end), c)
					s(end) = [];
				end
			end
		end
		
	end
	
	
	
end