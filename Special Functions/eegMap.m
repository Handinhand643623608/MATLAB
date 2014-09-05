function varargout = eegMap(data, varargin)
%EEGMAP Plots a spatial mapping of EEG electrodes and fills electrodes with color.
%
%   SYNTAX:
%   eegMap(X)
%   eegMap(C)
%   eegMap(..., 'PropertyName', PropertyValue,...)
%   H = eegMap(...)
%   
%   OPTIONAL OUTPUT:
%   H:              WINDOWOBJ
%                   A handle to the window object containing the plotted EEG map.
%   
%   INPUT:
%   X:              [68x1 NUMERIC]
%                   A numeric data vector with each element corresponding to one EEG electrode in the same ordering
%                   found within paramStruct and the EEG data objects. If numeric data is inputted into EEGMAP, it must 
%                   be in this format and size. The numeric data is automatically scaled to span the range of color
%                   values dictated by the figure's colormap.
%   
%   C:              'STR' OR {..., 'STR',...}
%                   A single string or cell array of multiple strings that determine which electrodes are colored on the
%                   map being generated. This can be used in lieu of the data input as a kind of "demo" mode wwhere the
%                   user chooses which electrodes on the map are highlighted. Each string should be the name of a single
%                   electrode (case insensitive). All electrodes not included on this input list are still drawn and 
%                   labeled but are colored black to blend in with the background.
%                   
%                   EXAMPLE:
%                       'FPZ' OR {'FPZ', 'AF7', 'C3}
%
%   OPTIONAL INPUTS:
%   'Color':        [1x3 RGB] OR 'STR'
%                   An RGB color vector or a MATLAB predefined color name string that specifies the color of filled
%                   electrodes on the map. This is only used when specific electrodes are inputted to be highlighted (C
%                   instead of X above). If numeric data is inputted to determine color values, this property has no
%                   effect.
%
%                   DEFAULT: [0 0.25 1] (a lighter blue)
%
%   'Labels':       BOOLEAN OR 'STR'
%                   A Boolean true/false or string on/off that specifies whether or not electrode text labels are
%                   displayed on the map. If enabled, labels are centered on top of the colored electrode circle.
%                   Otherwise, only a colored circle is displayed.
%   
%                   DEFAULT: 'on'
%                   OPTIONS:
%                       true    OR  'on'
%                       false   OR  'off'
%
%   'Size':         'STR'
%                   A string specifying how large the plot window should be. This is a setting carried directly over
%                   from the WINDOWOBJ class, and all options supported there are available.
%
%                   DEFAULT: 'fullscreen'
%                   OPTIONS:
%                       'fullscreen'    OR  'full'
%                       'halfscreen'    OR  'half'
%                       'quarterscreen' OR  'quarter'

%% CHANGELOG
%   Written by Josh Grooms on 20130902
%       20140109:   Major overhaul of function initialization to support a kind of "demo" mode where the user can
%                   manually select electrodes to be highlighted on the plot. Implemented custom color selection of
%                   highlighted electrodes (not available for data input). Hard coded some default color options that
%                   were infrequently changed before (edge, text, background colors). Implemented plotting to window
%                   objects instead of figures. Implemented the optional output of the window object handle. Completely
%                   re-wrote function documentation.
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).
%       20140904:   Bug fixes for compatibility with new COLOR class (required renaming a variable) and for deleting the
%                   list of EEG channels that this function used to reference (these data are now a part of the
%                   BRAINPLOT class).



%% Initialize
% Load data stored elsewhere
chanPath = where('BrainPlot.m');
load([chanPath '/eegInfo.mat'], 'channels');
load eegSpatialCoordinates.mat;

% Initialize defaults & settings
inStruct = struct(...
    'FillColor', [0 0.25 1],...
    'Labels', 'on',...
    'ParentAxes', [],...
    'Size', WindowSizes.FullScreen);
assignInputs(inStruct, varargin, 'compatibility', {'FillColor', 'color'});

% If no data is input, just display a colorless map
if nargin == 0 || isempty(data)
    data = channels;
end

% If running in demo mode (just seleting channels to be labeled), color the input channels
if ischar(data); data = {data}; end
if iscell(data)
    channelsToColor = data;
    data = zeros(length(channels), 3);
    if ischar(FillColor); FillColor = str2rgb(FillColor); end
    for a = 1:length(channelsToColor)
        data(strcmpi(channels, channelsToColor{a}), :) = FillColor;
    end
end

% Scale data to RGB values, if necessary
if size(data, 2) ~= 3; data = scale2rgb(data); end    

% Find pre-configured plot
classPath = fileparts(which('brainPlot.m'));
plotFig = [classPath '\eegPlot.fig'];

% Generate a figure
if isempty(ParentAxes)
    windowHandle = Window('Size', Size, 'Color', 'w');
    ParentAxes = axes(...
        'Box', 'off',...
        'Color', 'none',...
        'XLim', [0 1],...
        'XTick', [],...
        'YLim', [0 1],...
        'YTick', []); 
    windowHandle.Axes = ParentAxes;
    axis square
else
    windowHandle = get(ParentAxes, 'Parent');
end
    
    
    
if exist(plotFig, 'file')
    %% Load an Existing Plot (Saves Time)
    loadStruct = struct('Parent', ParentAxes);
    [plotHandles, ~] = hgload(plotFig, loadStruct);
    plotHandles = reshape(plotHandles, [0.5*size(plotHandles, 1), 2]);
    for a = 1:length(channels)
        set(plotHandles(a, 2),...
            'FaceColor', data(a, :),...
            'EdgeColor', 'w');
        set(plotHandles(a, 1),...
            'Color', 'w',...
            'FontUnits', 'points',...
            'FontSize', 12,...
            'FontWeight', 'normal');
        if ~istrue(Labels)
            set(plotHandles(a, 1), 'Visible', 'off');
        end
    end
        
else
    %% Generate a Spatial EEG Map
    % Produce the spatial maps
    plotHandles = zeros(length(channels), 2);
    szLabels = zeros(length(channels), 4);
    eegCoords = zeros(length(channels), 2);

    for a = 1:length(channels)
        % Get the electrode spatial coordinates
        eegCoords(a, :) = eegCoordinates.(channels{a});

        % Draw the text on the plot & set properties
        plotHandles(a, 1) = text(eegCoords(a, 1), eegCoords(a, 2), channels{a}, 'Parent', ParentAxes);
        set(plotHandles(a, 1),...
            'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'middle',...
            'FontUnits', 'normalized',...
            'FontWeight', 'bold');

        % Get the size of the labels to determine how to scale the circle
        szLabels(a, :) = get(plotHandles(a, 1), 'Extent');
    end

    % Get the maximum width of all text (in order to make surrounding circles consistent)
    maxWidth = max(szLabels(:, 3));

    % Initialize the circle patches
    theta = 0:(2*pi/(99)):2*pi;
    circleX = maxWidth.*sin(theta);
    circleY = maxWidth.*cos(theta);

    % Create the electrode circles on the plot
    for a = 1:length(data)
        % Adjust the spatial position
        currentX = circleX + eegCoords(a, 1);
        currentY = circleY + eegCoords(a, 2);

        % Create the circle object & set properties
        plotHandles(a, 2) = patch(currentX, currentY, 'k');
        set(plotHandles(a, 2),...
            'EdgeColor', 'w',...
            'FaceColor', data(a, :));

        % Delete & refresh the text data (so it's on top of the circle)
        delete(plotHandles(a, 1));
        plotHandles(a, 1) = text(eegCoords(a, 1), eegCoords(a, 2), channels{a}, 'Parent', ParentAxes);
        set(plotHandles(a, 1),...
            'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'middle',...
            'Color', 'w',...    
            'FontUnits', 'normalized',...
            'FontWeight', 'bold');    
    end
    
    % Save the figure for quick use in the future
    hgsave(plotHandles, plotFig);
end

% Fill in output object data
if isa(windowHandle, 'Window')
    windowHandle.Text = plotHandles(:, 1);
    windowHandle.Data.Patch = plotHandles(:, 2);
    windowHandle.Data.Color = data;
end
assignOutputs(nargout, windowHandle);    