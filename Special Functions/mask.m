function mx = mask(x, m, r)
% MASK - Nullifies values in a data array using a logical masking array.
%
%	SYNTAX:
%       mx = mask(x, m)
%		mx = mask(x, m, r)
%
%	OUTPUT:
%		mx:		[ NUMERICS ]
%				An array of the same size and type as the inputted data array x. Values in mx will either be r (if the
%				corresponding value of m is false) or x (if the corresponding value of m is true).
%
%	INPUTS:
%		x:		[ NUMERICS ]
%				The data array to be masked. This argument can be an array of any size or dimensionality of any numeric
%				data type (e.g. double, single, integer, Boolean, etc.). 
%
%		m:		[ BOOLEANS ]
%				The array of Boolean values that represents the mask. This argument must be an array of logical type.
%				Inputting an array of any other type is an error. The placement of false (i.e. zero) values in this
%				array determines where values values in x are nullified. Wherever "falses" exist, the corresponding
%				values in x will be set to the replacement value r. Conversely, values corresponding with "trues" in m
%				will be outputted in mx untouched.
%
%				m must also be an array that is either equal in size to x or is equal in size over all but the last
%				dimension of x, for which m has a singleton dimension. In other words, if x is of size [a, b,..., y, z],
%				then m may be of size [a, b,..., y, z] or [a, b,..., y, 1]. This is allowed in order to facilitate the
%				masking of data series that are stored in array form.
%
%	OPTIONAL INPUTS:
%		r:		NUMERIC
%				A single value of any numeric type that replaces any nullified values in x. By default, masked values
%				are replaced with zeros in this function, but NaN is another value that is commonly used for r.
%               DEFAULT: 0

%% CHANGELOG
%   Written by Josh Grooms on 20141001
%       20141008:   Improved the check for mask and data array size equality.
%		20141118:	Added documentation for this function. Also changed the name of the function from "maskImageSeries"
%					to "mask" in order to better reflect its capabilities (and because the function name "mask" isn't in
%					use elsewhere like I thought it was).
%		20141208:	Bug fix for array sizing assertion being tripped when trying to mask a two-dimensional array with a
%					vector, for which size is always specified using two numbers.



%% Perform the Masking
% Deal with missing inputs
if nargin == 2; r = 0; end

% Ensure that the mask is logical in type
assert(islogical(m), 'The array being used as a mask must be a logical array.');

% Get the inputted array & mask dimensionalities
szArray = size(x);
szMask = size(m);

% If the array & mask are equivalent in size, do a simple mask
if (isequal(szArray, szMask))
    mx = x .* m;
    return;
end

% If the inputted data don't match along all but the last dimension, error out
dimArray = ndims(x);
szCheck = isequal(szMask(1:dimArray - 1), szArray(1:end - 1));
assert(szCheck, 'The mask must be the same size as the inputted data array over all but the last dimension.');

% Mask the time series
mx = reshape(x, [], szArray(end));
m = m(:);
mx(~m, :) = r;
mx = reshape(mx, szArray);
