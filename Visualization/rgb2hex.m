function h = rgb2hex(r, g, b)
% RGB2HEX - Converts RGB color values into an equivalent hexadecimal notation.
%
%   This function converts from RGB color notation to the equivalent hexadecimal representation. Both notations are
%   frequently used to represent colors in various programming languages. Inputs to this function must be integers in
%   the range [0, 255] inclusive. Failure to provide numbers in this range is an error.
%
%   RGB2HEX outputs a string that is the hexadecimal notation for the inputted RGB values. This string will always be
%   six characters long, with each pair of characters representing one of the color channel values. 
%
%   SYNTAX:
%       h = rgb2hex(r, g, b)
%
%   OUTPUT:
%       h:      STRING
%               The hexadecimal notation for the color that the inputted RGB values represent.
%
%   INPUTS:
%       r:      INTEGER
%               The red color channel value. This integer must lie in the range [0, 255] inclusive.
%
%       g:      INTEGER
%               The green color channel value. This integer must lie in the range [0, 255] inclusive.
%
%       b:      INTEGER
%               The blue color channel value. This integer must lie in the range [0, 255] inclusive.

%% CHANGELOG
%   Written by Josh Grooms on 20141023
%		20150603:	Bug fix for the code that prepends zeros to any single-character hex codes that are found.



%% Convert from RGB Integers to a Hexadecimal String
% Error check
assert(all([r, g, b] <= [255, 255, 255]), 'RGB color values must always be less than 255.');
assert(all([r, g, b] >= [0, 0, 0]), 'RGB color values must always be greater than 0.');

% Convert to individual hex entries
h = { dec2hex(r) dec2hex(g) dec2hex(b) };

% Ensure that each entry has two characters, then concatenate & return
hexIsSingleChar = cellfun(@(x) length(x) == 1, h);
if any(hexIsSingleChar)
	h(hexIsSingleChar) = cellfun(@(x) ['0' x], h(hexIsSingleChar), 'UniformOutput', false);
end
h = [h{:}];
