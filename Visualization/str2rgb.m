function rgb = str2rgb(str)
% STR2RGB - Translates character strings into 3-element RGB color vectors.
%
%   SYNTAX:
%   rgb = str2rgb(str)
%
%   OUTPUT:
%   rgb:    [INTEGER, INTEGER, INTEGER]
%           A vector or array of RGB values representing the input color string(s). If a cell array of color strings is 
%           inputted, the output is a numerical array of the same dimensionality except that RGB values span a final
%           additional dimension. Thus, if the input is an M-by-N cell array of strings, the output is an M-by-N-by-3
%           array of RGB values.
%
%   INPUT:
%   str:    STRING
%           A character string or cell array of strings to be converted into RGB values.
%           OPTIONS:
%               'b' OR 'blue'
%               'c' OR 'cyan'
%               'a' OR 'gray'
%               'g' OR 'green'
%               'k' OR 'black'
%               'm' OR 'magenta'
%               'r' OR 'red'
%               'w' OR 'white'
%               'y' OR 'yellow'

%% CHANGELOG
%   Written by Josh Grooms on 20130803
%       20150211:   Added the color gray, coded as the character 'a'. Updated the documentation accordingly. Also added an
%                   error check for unrecognized character/string inputs. Added a deprecation method diverting users to my
%                   new COLOR class and its related static method FROMSTRING.

DEPRECATED Color.FromString



%% Convert Strings to Numeric RGB Values
if iscell(str)
    szStr = size(str);
    numDims = length(szStr);
    rgb = cellfun(@Translate, str, 'UniformOutput', false);
    rgb = cellfun(@(x) reshape(x, [ones(1, numDims) 3]), rgb, 'UniformOutput', false);
    rgb = cell2mat(rgb);
else
    rgb = Translate(str);
end



end %===============================================================================================
%% Nested Functions
function rgb = Translate(str)
    switch lower(str)
        case {'b', 'blue'}
            rgb = [0 0 1];
        case {'c', 'cyan'}
            rgb = [0 1 1];
        case {'a', 'gray'}
            rgb = [0.5, 0.5, 0.5];
        case {'g', 'green'}
            rgb = [0 1 0];
        case {'k', 'black'}
            rgb = [0 0 0];
        case {'m', 'magenta'}
            rgb = [1 0 1];
        case {'r', 'red'}
            rgb = [1 0 0];        
        case {'w', 'white'}
            rgb = [1 1 1];
        case {'y', 'yellow'}
            rgb = [1 1 0];
        otherwise
            error('Unrecognized color string %s found. See documentation for supported color codes.', str);
    end
end



