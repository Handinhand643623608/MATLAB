function varargout = shadePlot(varargin)
%SHADEPLOT
%
%   SYNTAX:
%   shadePlot(Y, Z)
%   shadePlot(X, Y, Z)
%   shadePlot(X, Y, Z, LineSpec)
%   shadePlot(X, Y, Z, LineSpec, 'PropertyName', PropertyValue,...)
%   H = shadePlot(...)
%
%   OPTIONAL OUTPUT:
%   H:          WINDOWOBJ
%               A handle to the window object containing the plotted data.
%
%   INPUTS:
%   Y:          [NUMERIC]
%               A vector of numeric data to be plotted. If no X data is provided, it is generated automatically from the
%               size of this vector. This vector can be in any orientation.
%
%   Z:          [NUMERIC]
%               A vector of numeric data to be plotted as shading around Y. Vector can be in any orientation.
%
%   OPTIONAL INPUTS:
%   X:
%
%   'Color':
%
%   'LineWidth':
%
%   'Position':
%
%   'ShadeColor':
%
%   'Size':
%
%   'Title':
%   
%   'XLabel':
%
%   'YLabel':

%% CHANGELOG
%   Written by Josh Grooms on 20130918
%       20131126:   Implemented titling & axes labeling within this function.
%       20140205:   Implemented the ability to plot a red threshold line for significance.
%       20140414:   Implemented the ability to plot to pre-existing axes. In this case, none of the axes font, color, 
%                   label, or line weight input settings are used.
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).


%% Initialize
% Deal with different combinations of inputs
[x, y, z, LineSpec, varCell] = parseInputs(varargin{:});
    
% Initialize a defaults & settings structure
inStruct = struct(...
    'AxesHandle', [],...
    'Color', [0.8 0.8 0.8],...
    'LineWidth', 5,...
    'Position', WindowPositions.CenterCenter,...
    'ShadeColor', [0.65 0.65 0.65],...
    'Size', WindowSizes.FullScreen,...
    'Title', [],...
    'Threshold', [],...
    'ThresholdColor', 'r',...
    'ThresholdLineWidth', 4,...
    'XLabel', [],...
    'YLabel', []);
assignInputs(inStruct, varCell);

if isempty(AxesHandle)
    % Generate a window object to contain the plot
    exclusionStrs = {'ShadeColor', 'LineWidth', 'Threshold', 'ThresholdColor', 'Title', 'XLabel', 'YLabel'};
    windowVars = struct2var(inStruct, exclusionStrs);
    figObj = Window(windowVars{:});

    % Initialize axes for the plot
    figObj.Axes = axes(...
        'Color', 'none',...
        'FontSize', 12,...
        'LineWidth', 2,...
        'XColor', ([1 1 1]-Color),...
        'YColor', ([1 1 1]-Color));
    currentAxes = figObj.Axes;
else
    figObj = gcf;
    currentAxes = gca;
end

% Deal with color strings
if ischar(Color); Color = str2rgb(Color); end
if ischar(ShadeColor); ShadeColor = str2rgb(ShadeColor); end

% Ensure data is in the correct orientation
if iscolumn(x); x = x'; end
if iscolumn(y); y = y'; end
if iscolumn(z); z = z'; end


%% Generate the Plot
% Generate the shading first
fill(...
    [x fliplr(x)],...
    [y+z fliplr(y-z)],...
    ShadeColor);
hold on

% Plot the solid line
plot(x, y, LineSpec, 'LineWidth', LineWidth);

% Plot the threshold, if it exists
if ~isempty(Threshold)
    plot(x, ones(1, length(x)).*Threshold, ['--' ThresholdColor], 'LineWidth', ThresholdLineWidth);
end

% Adjust axes parameters
if isempty(AxesHandle)
    set(get(currentAxes, 'XLabel'),...
        'FontSize', 25,...
        'String', XLabel);
    set(get(currentAxes, 'YLabel'),...
        'FontSize', 25,...
        'String', YLabel);
    set(get(currentAxes, 'Title'),...
        'FontSize', 25,...
        'String', Title);
end

% Generate outputs
assignOutputs(nargout, figObj);


end%====================================================================================================================
%% Nested Functions
function [x, y, z, LineSpec, varCell] = parseInputs(varargin)
    if nargin == 2
        x = 1:length(varargin{1}); y = varargin{1}; z = varargin{2}; LineSpec = '-k';
        varargin(1:2) = [];
    elseif nargin == 3 && isnumeric(varargin{3})
        x = varargin{1}; y = varargin{2}; z = varargin{3}; LineSpec = '-k';
        varargin(1:3) = [];
    elseif length(varargin) == 3 && ischar(varargin{3})
        x = 1:length(varargin{1}); y = varargin{1}; z = varargin{2}; LineSpec = varargin{3};
        varargin(1:3) = [];
    else
        x = varargin{1}; y = varargin{2}; z = varargin{3}; LineSpec = varargin{4};
        varargin(1:4) = [];
    end
    varCell = varargin;
end