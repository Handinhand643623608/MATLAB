classdef Range < Entity
% RANGE - A class that stores and manages range information about data arrays.

%% CHANGELOG
%	Written by Josh Grooms on 20150212
	
	
	
	%% DATA
	properties
		Max		@double			% The maximum value of the range.
		Min		@double			% The minimum value of the range.
	end
	
	properties (Dependent)
		Difference				% The difference between the maximum and minimum values.
	end
	
	
	
	%% PROPERTIES
	methods
		function d = get.Difference(R)
			d = R.Max - R.Min;
		end
	end
	
	
	
	%% CONSTRUCTOR
	methods
		function R = Range(varargin)
		% RANGE - Constructs a standardized range object from data collections.
			numchk = all(cellfun(@isnumeric, varargin));
			assert(numchk, 'Range objects can only be constructed from numeric data.');
			argmax = cellfun(@(x) max(x(:)), varargin);
			argmin = cellfun(@(x) min(x(:)), varargin);
			R.Max = max(argmax);
			R.Min = min(argmin);
		end
	end
	
	methods (Static)
		function R = FromData(x)
		% FROMDATA - Constructs a range object from an array of data.
			x = x(:);
			R = Range(min(x), max(x));
		end
	end
	
		
	
	%% UTILITIES
	methods
		function a = ToArray(R)
		% TOARRAY - Converts the range object into a two-element double-precision array.
		%
		%	This is the same as calling DOUBLE on the range object but is nevertheless provided to maintain consistency
		%	method consistency across all of my objects.
			a = [R.Min, R.Max];
		end
	end
		
	
	
	%% MATLAB OVERLOADS
	methods
		function d = diff(R)
		% DIFF - Gets the difference between the maximum and minimum values of the range object.
			d = R.Max - R.Min;
		end
		function d = double(R)
		% DOUBLE - Converts the range object into a two-element double precision array.
			d = [R.Min, R.Max];
		end
	end
	
	
	
end