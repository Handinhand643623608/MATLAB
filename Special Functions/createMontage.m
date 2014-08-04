function varargout = createMontage(axesHandles, figureHandles, varargin)
%CREATEMONTAGE Creates a montage of MATLAB figures of a default or specified dimension with great
%   flexibility. Unlike the MATLAB-native "montage" function, each element of this montage remains a
%   figure with infinite scalability. Furthermore, all of these elements remain editable after
%   creation.
% 
%   Syntax:
%   createMontage(axesHandles, figureHandles, 'propertyName', propertyValue,...)
% 
%   PROPERTY NAMES:
%   axesHandles:
% 
%   figureHandles:
% 
%   ('axesColor'):
%
%   ('backgroundColor'):
% 
%   ('colorBar'):
%
%   ('colorBounds'):
% 
%   ('colorMap'):
% 
%   ('figurePosition'):
% 
%   ('figureSize'):
% 
%   ('numRows'):
% 
%   ('numColumns'):
% 
%   ('spacing'):
% 
%   ('visibleCBar'):
% 
%   ('visibleFigs'):
% 
%   Written by Josh Grooms on 20130125
%       20130126 - Modified to output figure & axes handles for further modification



%% Initialize
% Create the defaults structure & assign inputs
inStruct = struct(...
    'axesColor', 'k',...
    'backgroundColor', [0.8 0.8 0.8],...
    'colorBar', 'on',...
    'colorBounds', [-1 1],...
    'colorMap', jet(64),...
    'figurePosition', 'right-center',...    
    'figureSize', 'default',...    
    'numRows', size(axesHandles, 1),...
    'numColumns', size(axesHandles, 2),...
    'spacing', 0,...
    'visibleCBar', 'on',...
    'visibleFigs', 'on');
assignInputs(inStruct, varargin)

% Create the figure
figureHandle = numel(figureHandles) + 1;
while ishandle(figureHandle)
    figureHandle = figureHandle + 1;
end
figureHandle = figure(figureHandle);
set(figureHandle, 'Colormap', colorMap, 'Visible', 'off');

% Set up the subplots
subAxesHandles = zeros(numel(axesHandles), 1);
progressbar('Elements of Montage Intializing')
for i = 1:numel(axesHandles)
    set(0, 'CurrentFigure', figureHandle);
    subAxesHandles(i) = subplot(numRows, numColumns, i);
    progressbar(i/numel(axesHandles));
end

% Get rid of subplot axes
set(subAxesHandles, 'Visible', 'off');


%% Copy Data Over from Existing Plots
% Transfer data from other plots to the subplot
progressbar('Copying Existing Plots to Montage')
axesHandles = axesHandles';
for i = 1:numel(axesHandles)
    copyobj(allchild(axesHandles(i)), subAxesHandles(i));
    set(subAxesHandles(i), 'CLim', colorBounds);
    progressbar(i/numel(axesHandles))
end
axis(subAxesHandles, 'tight');
close(figureHandles(:))


%% Scale the Montage to the Size of a Default Figure
% Resize the subplot axes to the designated spacing
set(figureHandle, 'Units', 'inches');
set(subAxesHandles, 'Units', 'inches');
positionMat = get(subAxesHandles, 'OuterPosition');
positionMat = cat(1, positionMat{:});

% Figure out by how much each plot needs to be scaled
defaultAxPos = [0.758333 0.48125 3.7986 3.56563];
totalWidth = defaultAxPos(3);
totalHeight = defaultAxPos(4);
diffWidth = positionMat(1, 3) + spacing - (totalWidth/numColumns);
diffHeight = positionMat(1, 4) + spacing - (totalHeight/numRows);

% Scale the data to the appropriate size
positionMat(:, 3) = positionMat(:, 3) - diffWidth;
positionMat(:, 4) = positionMat(:, 4) - diffHeight;
firstPos = positionMat(1, :);
firstPos(1) = defaultAxPos(1) + 0.5*spacing;
firstPos(2) = defaultAxPos(2) + 0.5*spacing + (numRows - 1)*(firstPos(4) + spacing);
positionMat(1, :) = firstPos;
set(subAxesHandles(1), 'Position', firstPos)


%% Translate the Individual Montage Images to their Final Positions
% Move the plots around to create the spacing
idxRow = 1;
progressbar('Repositioning Montage Elements')
for i = 2:size(positionMat, 1)
    currentX = positionMat(i, 1);
    currentY = positionMat(i, 2);
    lastX = positionMat((i - 1), 1);
    lastY = positionMat((i - 1), 2);
    if (i - 1) == idxRow*numColumns
        currentX = firstPos(1);
        currentY = lastY - firstPos(4) - spacing; 
        idxRow = idxRow + 1;
    else
        currentX = lastX + firstPos(3) + spacing;
        currentY = lastY;
    end
    
    positionMat(i, 1) = currentX;
    positionMat(i, 2) = currentY;
    
    set(subAxesHandles(i), 'Position', positionMat(i, :))
    progressbar(i/size(positionMat, 1))
end

szElement = [(positionMat(1, 3) + spacing) (positionMat(1, 4) + spacing)];


%% Create Supporting Imagery & Final Formatting
% Create new overall axes
set(0, 'CurrentFigure', figureHandle);
newAxes = axes;
set(newAxes, 'Units', 'inches')
set(newAxes,...
    'Color', 'none',...
    'CLim', colorBounds,...
    'Position', defaultAxPos,...
    'TickDir', 'out');

% Add a colorbar, if called for
defaultCBarPos = [4.7760 0.4635 0.2778 3.5729];
cbarHandle = colorbar;
set(cbarHandle, 'Units', 'inches')
cbarRange = sigFig((colorBounds(1):(diff(colorBounds)/10):colorBounds(2)), 'roundFormat', '0.00');
set(cbarHandle,...
    'Box', 'off',...
    'Position', defaultCBarPos,...
    'TickLength', [0 0],...
    'YLim', colorBounds,...
    'YTick', cbarRange,...
    'YTickLabel', cbarRange);

% Reset units setting on axes
set([figureHandle; newAxes; cbarHandle; subAxesHandles], 'Units', 'normalized');

% Finalize formatting settings
xTicks = (1/(2*numColumns)):(1/numColumns):(1 - (1/(2*numColumns)));
yTicks = (1/(2*numRows)):(1/numRows):(1 - (1/(2*numRows)));
set(newAxes,...
    'XColor', axesColor,...
    'XTick', xTicks,...
    'YTick', yTicks,...
    'YColor', axesColor)
    
if strcmpi(figureSize, 'default')        
    set(figureHandle,...
        'Color', backgroundColor,...
        'Colormap', colorMap,...
        'Visible', visibleFigs);
else
    createFigure(...
        'backgroundColor', backgroundColor,...
        'colorMap', colorMap,...
        'editFigure', figureHandle,...
        'figureSize', figureSize,...
        'figurePosition', figurePosition,...
        'visible', visibleFigs);
end

% Reset the colorbar width
normCBarPos = get(cbarHandle, 'Position');
set(cbarHandle, 'Position', normCBarPos, 'XColor', backgroundColor, 'ZColor', backgroundColor);

% Assign outputs
assignOutputs(nargout, figureHandle, newAxes, subAxesHandles, szElement)

