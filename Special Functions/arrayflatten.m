function [y, idsRemoved] = arrayflatten(x, removeValues)
% ARRAYFLATTEN - Flattens a numeric array into a column vector and optionally removes certain values.
%
%	SYNTAX:
%		y = arrayflatten(x)
%		y = arrayflatten(x, removeValues)
%		[y, idsRemoved] = arrayflatten(...)
%
%	OUTPUT:
%		y:				[ M x 1 NUMERIC ]
%						The flattened column vector of all values in x. This output will always be a column vector and
%						will be of length M <= NUMEL(x). Values that were inputted under the removeValues argument will
%						not be present in this vector. 
%
%						If the removeValues argument is omitted or is an empty array, y will be of length M = NUMEL(x).
%						In this case, calling this function is equivalent to invoking y = x(:).
%						
%
%	OPTIONAL OUTPUT:
%		idsRemoved:		[ L x 1 BOOLEANS ]
%						A column vector of Booleans indicating where values have been removed from the original
%						flattened version of x. This output will always be a column vector and will always be of length
%						L = NUMEL(x). Wherever values of this vector are TRUE, the corresponding elements of x were
%						removed and are not present in y.
%
%	INPUT:
%		x:				[ NUMERIC ]
%						An array of numeric values of any dimensionality and size that is to be flattened.
%
%	OPTIONAL INPUT:
%		removeValues:	[ NUMERIC ]
%						A vector of values that should be removed from x after flattening it. This vector may contain
%						any numeric values (including Inf and NaN) and may be of any length. Specifying values to remove
%						is useful when flattening data that contains dead or null elements that should not be processed
%						further (e.g. when producing a data histogram of a volumetric array with NaN-valued voxels). By
%						default, no values are removed from x, in which case the output 

%% CHANGELOG
%	Written by Josh Grooms on 20141124



%% Flatten the Array & Remove Any Specified Values
% Deal with missing inputs
if (nargin == 1); removeValues = []; end

% Error checks
assert(nargin >= 1, 'Not enough input arguments. An array of some numeric type must be inputted to be flattened.');
assert(isnumeric(x), 'The inputted array must be of some numeric type to be flattened.');
assert(isempty(removeValues) || isvector(removeValues), 'Values being removed must be specified as an empty array or as a vector of values.');

% Flatten & remove unwanted values
y = x(:);
idsRemoved = ismember(y, removeValues);
if (any(isnan(removeValues)))
	idsRemoved = idsRemoved | isnan(y);
end
y(idsRemoved) = [];



