function xr = sigfig(x, format, opt)
% SIGFIG - Rounds input numerical data to a specified number of significant figures with various rounding options.
% 
%   SYNTAX:
%       xr = sigfig(x)
%       xr = sigfig(x, format)
%       xr = sigfig(x, format, opt)
%
%   OUTPUT:
%       xr:             DOUBLE or [ DOUBLES ]
%                       A number or array of numbers that have been rounded to the specified number of significant digits.
%                       This argument will always be of the same size and dimensionality as the input x.
%
%   INPUT:
%       x:              DOUBLE or [ DOUBLES ]
%                       A number or array of numbers to be rounded to some specified significant figure. This argument may be
%                       an array of any size and dimensionality.
%
%   OPTIONAL INPUTS:
%       format:         STRING
%                       The desired format of the output that specifies the number of significant digits the output should
%                       have. This argument must be provided as a string in which the number of characters controls the
%                       number of significant (i.e. non-zero) digits each number in the output array will have. A single
%                       decimal point (the period or '.' character) may optionally be used to control significance of
%                       fractional number parts.
%
%                       The choice of character(s) used in this string is irrelevant; only the number of characters present
%                       and their placement relative to a decimal point is used. However, for clarity I recommend using zeros
%                       ('0').
%                       
%                       DEFAULT: '0.0'
% 
%                       EXAMPLES:
%                           '0.0'   - Round to the "tenths" decimal place
%                           '0.00'  - Round to the "hundredths" decimal place
%                           'x.xyz' - Round to the "thousandths" decimal place
%                           '0'     - Round to the nearest integer, same as "round" in MATLAB
%                           '00'    - Round to the "tens" integer place
%                           'xxx'   - Round to the "hundreds" integer place
%                           'abcd'  - Round to the "thousands" integer place (character choice doesn't matter)
%
%       opt:            STRING
%                       An option string dictating what method to use when rounding the input x to a significant figure. For
%                       the most part, acceptable options correspond with native MATLAB rounding functions. This argument is
%                       used in conjunction with the format argument above such that digits outside of the significant figure
%                       range influence rounding.
%
%                       DEFAULT: 'round'
%                       OPTIONS:
%                           'round' - Ordinary rounding towards the nearest significant figure. 
%                           'ceil'  - Values are rounded up towards positive infinity.
%                           'floor' - Values are rounded down towards negative infinity.
%                           'fix'   - Values are rounded towards zero.
%                           'unfix' - Values are rounded away from zero.
% 
% See also CEIL, FIX, FLOOR, ROUND

%% CHANGELOG
%   Written by Josh Grooms on 20130114
%       20130120:   Added a help section
%       20130318:   Implemented compatibility for variable names
%       20130523:   Updated variable name alternatives to include more likely inputs. 
%       20130603:   Updated help section for consistency with other custom functions.
%       20150114:   Renamed this function from 'sigFig' to 'sigfig' to simplify its use. Completely overhauled the 
%                   documentation and logic to conform with updated standards.


%% Round the Data
% Fill in optional inputs & check for errors
if nargin < 3; opt = 'round'; end
if nargin < 2; format = '0.0'; end
assert(ischar(opt) && ischar(format), 'Optional arguments must be inputted as strings.');

% Identify any decimal points present in the format string
idxDecPt = strfind(format, '.');
nformat = length(format);

% Calculate a scaling factor using the format string
if isempty(idxDecPt) 
    roundFactor = 10 ^ (1 - nformat);
elseif idxDecPt == length(format)
    roundFactor = 10 ^ (2 - nformat);
else
    roundFactor = 10 ^ (nformat - idxDecPt);
end
    
% Scale the input data to the appropriate magnitude & perform the rounding
xr = x .* roundFactor;
if strcmpi(opt, 'unfix'); 
    xr(xr < 0) = floor(xr(xr < 0)); 
    xr(xr > 0) = ceil(xr(xr > 0));
else
    xr = feval(opt, x .* roundFactor);
end

% Unscale the output
xr = xr ./ roundFactor;