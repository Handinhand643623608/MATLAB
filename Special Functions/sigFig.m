function outData = sigFig(inData, varargin)
%SIGFIG Rounds input numerical data to a specified number of significant figures with various
%   rounding options.
% 
%   Syntax:
%   outData = sigFig(inData, 'propertyName', propertyValue,...)
% 
%   OUTPUT:
%   outData:            A number or array of numbers that have been rounded to the specified format
%                       using the specified options. Data are of the same dimensions as the input
%                       data.
% 
%   INPUTS: (values in parentheses are optional)
%   inData:             A number or array of numbers to be rounded to some specified significant
%                       figure using a specified or default property.
% 
%   ('format'):    The desired format of the output. This is a string representing the general
%                       form of the rounding (which digit to round to). Choice of character in the
%                       string does not matter.
%                       DEFAULT: '0.0' (Round to the first decimal place)
%                       EXAMPLES:
%                           '0.0'   (Round to the "tenths" decimal place
%                           '0.00'  (Round to the "hundredths" decimal place)
%                           'x.xxx' (Round to the "thousandths" decimal place)
%                           '0'     (Round to the nearest integer, same as "round" in MATLAB)
%                           '00'    (Round to the "tens" integer place)
%                           'xxx'   (Round to the "hundreds" integer place)
%                           '0000'  (Round to the "thousands" integer place)
% 
%   ('direction'):      Option dictating how to round the input data. This is a string of the same
%                       rounding commands used in MATLAB.
%                       DEFAULT: 'round'
%                       OPTIONS:
%                           'round' (Ordinary round, where numbers outside of the significant figure
%                                   range dictate the direction of round. E.g: 0.5 round to 1, while
%                                   0.4 rounds to 0. This follows the 'roundFormat' command so that
%                                   if '000' is selected, 50 rounds to 100 and 40 rounds to 0).
%                           'ceil'  (Rounds values up towards positive infinite)
%                           'floor' (Rounds values down towards negative infinite)
%                           'fix'   (Rounds values down/up towards zero)
%                           '-fix'  (Rounds values down/up away from zero. This command is not
%                                   native to MATLAB)
% 
%   Written by Josh Grooms on 20130114
%       20130120:   Added a help section
%       20130318:   Implemented compatibility for variable names
%       20130523:   Updated variable name alternatives to include more likely inputs. 
%       20130603:   Updated help section for consistency with other custom functions.


%% Initialize
% Set up defaults structure
inStruct = struct(...
    'roundFormat', '0.0',...
    'roundOpt', 'round');
assignInputs(inStruct, varargin,...
    'compatibility', {'roundFormat', 'format', 'roundTo';
                      'roundOpt', 'round', 'direction'});
                  

%% Round out the Data
% Determine how to refactor the data
idxStart = regexp(roundFormat, '\.');
if isempty(idxStart)
    roundFactor = 1/(10^(length(roundFormat) - 1));
else
    roundFactor = 10^(length(roundFormat) - idxStart);
end

% Create output data
outData = zeros(size(inData));
switch roundOpt
    case '-fix'
        outData(inData < 0) = floor(inData(inData < 0).*roundFactor)./roundFactor;
        outData(inData > 0) = ceil(inData(inData > 0).*roundFactor)./roundFactor;
    otherwise
        outData = eval([roundOpt '(inData.*roundFactor)./roundFactor;']);
end
