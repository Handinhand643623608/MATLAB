function varargout = scale2rgb(inData, varargin)
%SCALE2RGB - Scales an array of input numerical magnitude data to a colormapping.
%   This function accomplishes the same thing that is done in the native function "imagesc", where image data are
%   automatically scaled and mapped onto a range of colors.
% 
%   Syntax
%   rgbData = scale2rgb(inData)
%   rgbData = scale2rgb(inData, 'PropertyName', PropertyValue,...)
%   [rgbData, dataRange, numColors] = scale2rgb(...)
% 
%   OUTPUTS:
%   rgbData:        ARRAY
%                   An array of the same dimensions as the input data with an additional end dimension of '3'
%                   representing each of the RGB values assigned to the magnitude. Thus, if the input data is of size
%                   [10 20 30], the output data is [10 20 30 3] in size.
%
%   OPTIONAL OUTPUTS: 
%   dataRange:      [DOUBLE, DOUBLE]
%                   A two element vector of the global minimum and maximum of data magnitudes (not RGB values). The
%                   format of this variable is [MIN MAX].
%                   DEFAULT: [min(inData(:)), max(inData(:)]
% 
%   numColors:      INTEGER
%                   The number of colors in the designated colormap data is being scaled to. 
%                   DEFAULT: 256 (when no colormap is specified, see 'colorMap' property description)
% 
%   INPUT:
%   inData:         [DOUBLE]
%                   An array of numerical input values of any size and dimensionality. This is the data to be converted
%                   into scaled RGB values.
%
%   OPTIONAL INPUT: 
%   'Colormap':     COLORMAP
%                   The designated colormapping. This is specified as is ordinarily done in MATLAB (e.g. jet(64),
%                   hsv(128), cool(256), etc). The number inside the colormap call represents how many color steps are
%                   to exist in the colormapping.
%                   DEFAULT: jet(256)
%
%   'CLim'          STRING or [DOUBLE, DOUBLE]
%                   The range in data units over which to generate color values. This is a two-element vector specifying
%                   the [MIN MAX] values corresponding to the lowest and highest color of the colormap property. This
%                   parameter also accepts a string of 'auto', which determines color extremes using the minimum and
%                   maximum data values. 
%                   DEFAULT: 'auto'
% 
%   'NaNColor':     [R, G, B] or STRING
%                   The designated color of any "NaN" values in the data in RGB format. This argument can be one of the
%                   MATLAB single-character color strings or a three-element RGB vector. The default color is black.
%                   DEFAULT: [0 0 0]

%% CHANGELOG
%   Written by Josh Grooms on 20130114
%       20130117:   Added a help section
%       20130120:   Updated the help section
%       20130702:   Added documentation for "DataRange" property. Updated function to conform to recent standards.
%       20140625:   Updated documentation.
%       20140709:   Updated so that NaN colors can be specified as MATLAB color strings.



%% Initialize
% Create defaults
inStruct = struct(...
    'ColorMap', [jet(256)],...
    'DataRange', [],...
    'NaNColor', [0 0 0]);
assignInputs(inStruct, varargin,...
    'compatibility', {'ColorMap',  'colormap',  'color';
                      'DataRange', 'range',     'clim';
                      'NaNColor',  'nancolor',  'nan'});

% Store the original data dimensions & flatten
szDataOriginal = size(inData);
inData = reshape(inData, [numel(inData) 1]);

% Get the range of the data
if isempty(DataRange)
    minData = min(inData);
    maxData = max(inData);
    DataRange = [minData maxData];
else
    minData = min(DataRange);
    maxData = max(DataRange);
end

% Convert color strings to RGB
if ischar(NaNColor); NaNColor = str2rgb(NaNColor); end



%% Convert Data to RGB Values
% Get the color mapping
numColors = size(ColorMap, 1);

% Deal with any NaNs in the data
idsNaN = find(isnan(inData));
inData(idsNaN) = 0;

% Get indices of RGB values in color mapping for each data point
idsColors = min(numColors, round((numColors - 1)*(inData - minData)/(maxData - minData)) + 1);

% Set data outside of the color ranges to the minimum & maximum colors
idsColors(idsColors < 1) = 1;
idsColors(idsColors > numColors) = numColors;

% Convert data to RGB values
rgbData = ColorMap(idsColors, :);

% Set specific color for NaN values (black by default)
for i = 1:length(idsNaN)
    rgbData(idsNaN(i), :) = NaNColor;
end

% Reshape the data to the original dimensions (getting rid of singletons)
rgbData = squeeze(reshape(rgbData, [szDataOriginal 3]));

% Assign the outputs
assignOutputs(nargout, rgbData, DataRange, numColors);
