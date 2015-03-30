classdef String < Entity
% String - A collection of utility functions that specifically operate on or produce strings.

%% CHANGELOG
%	Written by Josh Grooms on 20150212



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