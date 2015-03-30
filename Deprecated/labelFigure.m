function varargout = labelFigure(varargin)
%LABELFIGURE Labels the x and y axes of the current figure with custom labels and formatting
%   options. Axis labels can be applied at any rotation, on either side of the figure, in any color,
%   and in bold/italics/underlined. Currently, this function only works for 2-dimensional figures.
%   Uses the new name/value pairing of input arguments in any order.
% 
%   WARNING: Use of tick label rotation on long strings will result in overlap with any axis labels
%   that may be present. Furthermore, use of x-tick-labels at the top of the plot may overlap with
%   the plot title. This is a known bug to be fixed in the future.
% 
%   Syntax:
%   labelFigure('propertyName', propertyValue...)
% 
%   AXIS PROPERTY NAMES: (Substitute "x" with "y" in any of the below to control values on the y-axis)
%   ('xLabels'):        A string or cell array of strings of axis tick labels to be applied to the
%                       figure.
% 
%   ('xSide'):          A string indicating the side of the plot to create the axis tick labels
%                       SUPPORTED VALUES:
%                           'bottom'    (places tick labels on the bottom of the plot)
%                           'top'       (places tick labels on the top of the plot)
%                           'both'      (places the same tick labels on the top and bottom of the
%                                        figure)
%                           
%                       SUPPORTED 'ySide' VALUES:
%                           'left'      (places tick labels on the left side of the plot)
%                           'right'     (places tick labels on the right side of the plot)
%                           'both'      (places the same tick labels on the left and right of the
%                                        figure)
% 
%                       DEFAULT: ('xSide': 'bottom'), ('ySide': 'left')
% 
%   ('xRotation'):      A number indicating the degree of rotation desired for the axis tick labels.
%                       SUPPORTED VALUES:
%                           [-90 <= 'xRotation' <= 90]
%                           [-90 <= 'yRotation' <= 90]
% 
%                       DEFAULT: ('xRotation': 0), ('yRotation': 0)
% 
%   ('xFontAngle'):     A string indicating the angle of the font desired for the axis tick labels.
%                       SUPPORTED VALUES:
%                           'normal'    (no font angle)
%                           'italic'    (font slanted in italics)
%                           'oblique'   (font slanted in obliques)
% 
%                       DEFAULT: ('xFontAngle': 'normal'), ('yFontAngle': 'normal')
% 
%   ('xFontWeight'):    A string indicating the weight of the font desired for the axis tick labels.
%                       SUPPORTED VALUES:
%                           'normal'    (normal font weight)
%                           'bold'      (bold font weight)
%                           'light'     (light font weight)
%                           'demi'      (demi font weight)
% 
%                       DEFAULT: ('xFontWeight': 'normal'), ('yFontWeight': 'normal')
% 
%   ('xFontSize'):      A number indicating the font size in font units of the axis tick labels.
%                       DEFAULT: ('xFontSize': 10), ('yFontSize': 10)
% 
%   ('xColor'):         A three-element RGB vector or MATLAB standard character-string representing
%                       the color of the font for the axis tick labels.
%                       DEFAULT: ('xColor': [0 0 0]), ('yColor': [0 0 0])
%   
%   FIGURE PROPERTY NAMES: 
%   ('tickDir'):        A string controlling the direction of the individual ticks on each axis. 
%                       SUPPORTED VALUES:
%                           'in'    (ticks will be oriented inwards, overlapping the edges of the
%                                    figure area)
%                           'out'   (ticks will be oriented outwards and can be seen outside of the
%                                    figure area)
% 
%                       DEFAULT: 'in'
% 
%   Written by Josh Grooms on 20130105
%       20130112:   Updated to work with assignInputs. Added a rudimentary help section
%       20130120:   Added an extensive help section
%       20130126:   Updated to allow normalization of text & modification of specific figures & axes
%       20130127:   Updated to add plot & axes titles with options & to allow outputs of handles
%       20130416:   Removed "imageFlag" input. This can be determined automatically. Updated to
%                   convert axis units to "pixels" for text placement.
%       20130829:   Recovered basic functionality of this program. Still needs work, though.
%
% TODO: This function isn't working properly anymore (setting text labels in standard positions for
%       a correlation matrix image). Need to fix something...

%% Initialize
% Setup the options structure with defaults
inStruct = struct(...
    'axisHandle', gca,...
    'figureHandle', gcf,...
    'plotTitle', [],...
    'plotTitleColor', [0 0 0],...
    'plotTitleFontSize', 16,...
    'tickDir', 'in',...
    'xColor', [0 0 0],...
    'xFontAngle', 'normal',...    
    'xFontSize', 10,...
    'xFontWeight', 'normal',...
    'xLabels', [],...
    'xRotation', 0,...
    'xSide', 'bottom',...
    'xTitle', [],...
    'xTitleFontSize', 12,...
    'yColor', [0 0 0],...
    'yFontAngle', 'normal',...    
    'yFontSize', 10,...
    'yFontWeight', 'normal',...
    'yLabels', [],...
    'yRotation', 0,...
    'ySide', 'left',...
    'yTitle', [],...
    'yTitleFontSize', 12);
assignInputs(inStruct, varargin);


% Get tick positions on the axes
xTickPositions = get(axisHandle, 'XTick');
yTickPositions = get(axisHandle, 'YTick');
if ~isempty(xLabels) && length(xTickPositions) ~= length(xLabels)
    set(axisHandle, 'XTick', 1:length(xLabels));
    xTickPositions = get(axisHandle, 'XTick');
end
if ~isempty(yLabels) && length(yTickPositions) ~= length(yLabels)
    set(axisHandle, 'YTick', 1:length(yLabels));
    yTickPositions = get(axisHandle, 'YTick');
end

% Change figure tick direction
if strcmp('off', tickDir)
    set(axisHandle, 'XTick', [], 'YTick', []);
else
    set(axisHandle, 'TickDir', tickDir);
end

% Determine if the y-axis has been flipped (usually for image display)
if strcmp(get(gca, 'YDir'), 'reverse')
    imageFlag = true;
else
    imageFlag = false;
end

% Make sure the desired axes are the current focused axes & units are set to "pixels"
oldUnits = get(axisHandle, 'Units');
set(axisHandle, 'Units', 'pixels');
axes(axisHandle);
axesPosition = get(axisHandle, 'OuterPosition');



%% Place the Axes Labels
% Place the x-tick labels first (if applicable)
if ~isempty(xLabels)
    % Wipe the current labels
    set(axisHandle, 'XTickLabel', []);
    
    % Get the desired label inputs & convert to strings (if necessary)
    if isnumeric(xLabels)
        xLabels = num2cell(xLabels);
    end
    
    % Determine the label y coordinates & account for imagesc flipping the y-axis
    if imageFlag
        yTop = zeros(length(xTickPositions), 1);
        yBottom = ones(length(xTickPositions), 1).*length(yTickPositions) + 1;
    else
        yBottom = zeros(length(xTickPositions), 1);
        yTop = ones(length(xTickPositions), 1).*length(yTickPositions) + 1;
    end
    
    % Place the labels
    switch xSide
        case 'both' 
            % Place the text (bottom of plot first, then top)
            xText(:, 1) = text(xTickPositions, yBottom, xLabels);
            xText(:, 2) = text(xTickPositions, yTop, xLabels);
        case 'top'
            xText = text(xTickPositions, yTop, xLabels);
        otherwise
            xText = text(xTickPositions, yBottom, xLabels);
    end
end

% Place the y-tick labels (if applicable)
if ~isempty(yLabels)
    % Wipe the current labels
    set(axisHandle, 'YTickLabel', []);
    
    % Get the desired label inputs & convert to strings (if necessary)
    yLabels = yLabels;
    if isnumeric(yLabels)
        yLabels = num2cell(yLabels);
    end
    
    % Get the label coordinates
    if imageFlag
        xLeft = axesPosition(1)*ones(length(yTickPositions), 1) - 1;
        xRight = (axesPosition(1) + axesPosition(3))*ones(length(yTickPositions), 1) + 1;
    else               
        xLeft = axesPosition(1)*ones(length(yTickPositions), 1) - 0.1*(xTickPositions(2) - xTickPositions(1));
        xRight = (axesPosition(1) + axesPosition(3))*ones(length(yTickPositions), 1) + 0.1*(xTickPositions(2) - xTickPositions(1));
    end
    
    % Place the labels
    switch ySide
        case 'both'
            % Place the y-axis tick text
            yText(:, 1) = text(xLeft, yTickPositions, yLabels);
            yText(:, 2) = text(xRight, yTickPositions, yLabels);
        case 'right'
            yText = text(xRight, yTickPositions, yLabels);
        otherwise
            yText = text(xLeft, yTickPositions, yLabels);
    end
end


%% Set the Text Options
% Set the x-tick label options first (if applicable)
if ~isempty(xLabels)
    % Set all other options first
    for i = 1:size(xText, 2)
        set(xText(:, i),...
            'Rotation', xRotation,...
            'FontAngle', xFontAngle,...
            'FontWeight', xFontWeight,...
            'FontSize', xFontSize,...
            'Color', xColor);
    end
end
% Set the y-tick label options (if applicable)
if ~isempty(yLabels)
    % Set all other options first
    for i = 1:size(yText, 2)
        set(yText(:, i),...
            'Rotation', yRotation,...
            'FontAngle', yFontAngle,...
            'FontWeight', yFontWeight,...
            'FontSize', yFontSize,...
            'Color', yColor);
    end
end


%% Align the Text to the Axes
% Align the x-tick labels first
if ~isempty(xLabels)
    % Make the adjustments
    switch xSide
        case 'both'
            % Bottom of plot first            
            if xRotation == 0
                set(xText(:, 1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
                set(xText(:, 2), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            elseif xRotation >= -90 && xRotation < 0
                set(xText(:, 1), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
                set(xText(:, 2), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
            elseif xRotation > 0 && xRotation <= 90
                set(xText(:, 1), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
                set(xText(:, 2), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
            end
        case 'top'
            if xRotation == 0
                set(xText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            elseif xRotation >= -90 && xRotation < 0
                set(xText, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
            elseif xRotation > 0 && xRotation <=90
                set(xText, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
            end
        otherwise
            if xRotation == 0
                set(xText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
            elseif xRotation >= -90 && xRotation < 0
                set(xText, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
            elseif xRotation > 0 &&  xRotation <= 90
                set(xText, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
            end
    end
    textHandles = {xText};
end

% Align the y-tick labels next
if ~isempty(yLabels)       
    % Make the adjustments
    switch ySide
        case 'both'
            % Left of plot first
            if yRotation > -90 && yRotation < 90
                set(yText(:, 1), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
                set(yText(:, 2), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
            elseif yRotation == -90
                set(yText(:, 1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
                set(yText(:, 2), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            elseif yRotation == 90
                set(yText(:, 1), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                set(yText(:, 2), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
            end
        case 'right'
            if yRotation > -90 && yRotation < 90
                set(yText, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
            elseif yRotation == -90
                set(yText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            elseif yRotation == 90
                set(yText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
            end
        otherwise
            if yRotation > -90 && yRotation < 90
                set(yText, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
            elseif yRotation == -90
                set(yText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
            elseif yRotation == 90
                set(yText, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
    end
    
    textHandles = [textHandles {yText}];
end


%% Make a Plot Title
titleHandles = [];
if ~isempty(plotTitle)
    titleHandle = title(plotTitle);
    set(titleHandle,...
        'FontSize', plotTitleFontSize,...
        'FontWeight', 'bold',...
        'Color', plotTitleColor);
    set(titleHandle, 'Units', 'normalized');
    titleHandles = {titleHandle};
end

%% Make Axis Titles
if ~isempty(xTitle)
    % Calculate positioning of the title
    xTextExtents = get(xText, 'Extent');
    xTextExtents = cat(1, xTextExtents{:});
    xTitleY = min(xTextExtents(:, 2));
    xTitleHandle = xlabel(xTitle);
    newXTitlePos = get(xTitleHandle, 'Position');
    newXTitlePos(2) = xTitleY;
    
    % Set the title positioning
    set(xTitleHandle,...
        'FontSize', xTitleFontSize,...
        'FontWeight', 'bold',...
        'Color', xColor,...
        'Position', newXTitlePos);
    
    % Nomalize all x-axis text
    set([xTitleHandle; xText], 'Units', 'normalized');
    titleHandles = [titleHandles {xTitleHandle}];
end
if ~isempty(yTitle)
    % Calculate positioning of the title
    yTextExtents = get(yText, 'Extent');
    yTextExtents = cat(1, yTextExtents{:});
    yTitleX = min(yTextExtents(:, 1));
    yTitleHandle = ylabel(yTitle);
    newYTitlePos = get(yTitleHandle, 'Position');
    newYTitlePos(1) = yTitleX;
    
    % Set the title positioning
    set(yTitleHandle,...
        'FontSize', yTitleFontSize,...
        'FontWeight', 'bold',...
        'Color', yColor,...
        'Position', newYTitlePos);
    
    % Normalize all y-axis text
    set([yTitleHandle; yText], 'Units', 'normalized');
    titleHandles = [titleHandles {yTitleHandle}];
end

% Return the axes to their old units
set(axisHandle, 'Units', oldUnits); 

% Assign outputs
assignOutputs(nargout, textHandles, titleHandles)