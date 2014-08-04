function varargout = u_colormap_EEG(inData, eegLabels, varargin)
% u_EEG_COLORMAP Produces a spatial map of EEG electrodes that are filled with a color related to
%   the magnitude of the input data. The EEG montage is plotted according to the International 10-10
%   System standard. Input scalars are automatically scaled to the appropriate color value and color
%   mapping. 
% 
%   Syntax:
%   u_EEG_colormap(inData, eegLabels, 'propertyName', propertyValue,...)
% 
%   PROPERTY NAMES:
%   inData:                 A vector of scalar data, one element per EEG channel, that is to be
%                           scaled to a RGB color value and plotted inside of a spatial
%                           approximation of the EEG montage. These data must be of the same size as
%                           the cell array of EEG labels also being inputted.
% 
%   eegLabels:              A cell array of EEG channel label strings in the same order as the input
%                           data and of the same length.
% 
%   ('colorMap'):           The style of color mapping can be manually selected according to
%                           natively available MATLAB options. Number of color intervals can also be
%                           selected.
%                           DEFAULT: jet(256)
% 
%   ('colorBounds'):        A two-element vector of upper and lower bounds for the color axis that
%                           is used in the figure. This can be set so that figures are consistent
%                           across a multitude of data sets with varying minimums and maximums.
%                           EXAMPLE: [-1 1]
%                           DEFAULT: [min(inData(:)) max(inData(:))]
% 
%   ('figureSize'):         A string representing the size of the figure that is to be generated in
%                           terms of the current primary monitor's screen resolution. Figure is
%                           currently always generated on the right side of the monitor.
%                           EXAMPLES:
%                               'quarterScreen' (figure is generated at half the screen height and
%                                                width)
%                               'halfScreen'    (figure is generated at half the screen width if
%                                                monitor is in landscape orientation, or half the
%                                                height if in portrait)
%                               'fullScreen'    (figure is generated as a fullscreen window)
% 
%   ('fontAngle'):          A string indicating the desired angle of the fonts used in the figure.
%                           EXAMPLES:
%                               'normal'
%                               'italic'
%                               'oblique'
% 
%                           DEFAULT: 'normal'
% 
%   ('fontSize'):           
% 
%   ('fontUnits'):
% 
%   ('fontWeight'):
% 
%   ('fontColor'):
% 
%   ('patchResolution'):
% 
%   ('visibleCBar'):
% 
%   ('visibleFigs'):
%   COLORBOUNDS:    A two-element vector ([lower upper]) denoting the minimum
%                   and maximum values being mapped to colors.
% 
%   Written by Josh Grooms on 4/19/2012
%       Modified on 5/29/2012 to include option for custom labels
%       Modified on 5/31/2012 to include option for subject 7+ channel labels
%       Modified on 6/4/2012 to include extra channel labels for subject 7+
%       Modified heavily on 7/27/2012 to work with new data structures
% 
%   Completely re-written by Josh Grooms on 20130124 to integrate the new system of inputs, take
%   over the functions of the poorly-written subfunctions it used to call, and offer far more
%   flexibility in figure generation
%       20130125 - Updated with bug fixes & added ability to change patch edge colors

%% Initialize
% Initialize the defaults structure & assign input variables
inStruct = struct(...
    'backgroundColor', 'w',...
    'circleColor', 'k',...
    'colorMap', jet(256),...
    'colorBounds', [min(inData(:)) max(inData(:))],...
    'figureSize', 'default',...
    'fontAngle', 'normal',...    
    'fontColor', 'k',...    
    'fontSize', 6,...
    'fontUnits', 'normalized',...    
    'fontWeight', 'bold',...    
    'patchResolution', 100,...
    'visibleCBar', 'on',...    
    'visibleFigs', 'on',...
    'visibleFonts', 'on');   
assignInputs(inStruct, varargin);

% Load data stored elsewhere
load eegSpatialCoordinates.mat;

% Initialize data needed for the circle patch (start with a unit circle)
theta = 0:(2*pi/(patchResolution - 1)):2*pi;
circleX = sin(theta);
circleY = cos(theta);

% Initialize the figure & properties
figHandle = figure('Visible', visibleFigs);
axesHandle = gca;
axis equal;
axis([0 1 0 1]);


%% Produce the Spatial Maps of the Data
txtHandles = zeros(length(eegLabels), 1);
szLabels = zeros(length(eegLabels), 4);
eegCoords = zeros(length(eegLabels), 2);
for i = 1:length(eegLabels)
    % Get the electrode spatial coordinates
    eegCoords(i, :) = eegCoordinates.(eegLabels{i});
    
    % Draw the text on the plot & set properties
    txtHandles(i) = text(eegCoords(i, 1), eegCoords(i, 2), eegLabels{i});
    set(txtHandles(i),...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'middle',...
        'Color', fontColor,...    
        'FontAngle', fontAngle,...
        'FontSize', fontSize,...
        'FontUnits', fontUnits,...
        'FontWeight', fontWeight);
    
    % Get the size of the labels to determine how to scale the circle
    szLabels(i, :) = get(txtHandles(i), 'Extent');
end

% Get the maximum width of all text (in order to make surrounding circles consistent)
maxWidth = max(szLabels(:, 3));

% Create the electrode circles on the plot
circleHandles = zeros(length(inData), 1);
for i = 1:length(inData)
    % Adjust the scale first
    scaleFactor = 0.5*maxWidth;
    currentX = scaleFactor.*circleX;
    currentY = scaleFactor.*circleY;
    
    % Adjust the spatial position
    currentX = currentX + eegCoords(i, 1);
    currentY = currentY + eegCoords(i, 2);
    
    % Create the circle object & set properties
    circleHandles(i) = patch(currentX, currentY, 'w');
    set(circleHandles(i),...
        'CData', inData(i),...
        'CDataMapping', 'scaled',...
        'EdgeColor', circleColor,...
        'FaceColor', 'flat',...
        'LineWidth', 0.5);
    
    % Delete & refresh the text data (so it's on top of the circle)
    delete(txtHandles(i));
    if strcmpi(visibleFonts, 'on')
        txtHandles(i) = text(eegCoords(i, 1), eegCoords(i, 2), eegLabels{i});
        set(txtHandles(i),...
            'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'middle',...
            'Color', fontColor,...    
            'FontAngle', fontAngle,...
            'FontSize', fontSize,...
            'FontUnits', fontUnits,...
            'FontWeight', fontWeight);
    end
end

%% Finalize Plot Formatting
% Set axes properties of the figure
set(axesHandle,...
    'CLim', colorBounds,...
    'XTick', [],...
    'YTick', [],...
    'Visible', 'off');
axis tight

% Set colorbar properties of the figure
cbarHandle = colorbar;
set(cbarHandle,...
    'Visible', visibleCBar);

if strcmpi(figureSize, 'default')
    set(figHandle,...
        'Color', backgroundColor,...
        'Colormap', colorMap,...
        'InvertHardcopy', 'off',...
        'Renderer', 'painters',...
        'Visible', visibleFigs);
else
    createFigure(...
        'editFigure', figHandle,...
        'backgroundColor', backgroundColor,...
        'colorMap', colorMap,...
        'figurePosition', 'right-center',...
        'figureSize', figureSize,...
        'plotToMonitor', 'primary',...
        'visible', visibleFigs);    
end

% Assign output variables, if called for
assignOutputs(nargout, figHandle, axesHandle, txtHandles, circleHandles)