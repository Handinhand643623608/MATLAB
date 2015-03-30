classdef Array
% ARRAY - A collection of utility functions that specifically operate on multidimensional numeric data arrays.

%% CHANGELOG
%	Written by Josh Grooms on 20150219



	%% UTILITIES
	methods (Static)
		
		
		function y = Flatten(x)
		% FLATTEN - Reshapes a multidimensional array into a two-dimensional one.
			szx = size(x);
			y = reshape(x, [], szx(end));
		end
		function y = Threshold(x, bounds, replace)
		% THRESHOLD - Replaces values in an array that are between a set of bounds.
			assert(nargin >= 2, 'A set of boundary values must be provided in order to threshold X.');
			if (nargin < 3); replace = NaN; end
			if ~isa(bounds, 'Range'); bounds = Range(bounds); end
			
			y = x;
			y(x > bounds.Min & x < bounds.Max) = replace;
		end
	end
	
	
	
end