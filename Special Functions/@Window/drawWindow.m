function drawWindow(windowHandle, varargin)
%DRAWWINDOW Initializes the figure window with input properties.



%% CHANGELOG
%   Written by Josh Grooms on 20130206
%       20130801:   Updated method name for consistency with other objects. Major overhaul of object
%                   to make it more lightweight and easy to deal with. Removed the massive changelog
%                   (see SVN for the complete listing).
%       20130803:   Removed presets altogether (these should go in their respective subclass
%                   definintions). Wrote a separate function for converting strings to RGB values.



%% Initialize
% Initialize a defaults structure
inStruct = struct(...
    'Color', [0.8 0.8 0.8],...
    'Colorbar', [],...
    'Colormap', jet(64),...
    'FigureNumber', [],...
    'InvertHardcopy', 'off',...
    'MenuBar', 'none',...
    'Name', [],...
    'NumberTitle', 'on',...
    'PaperPositionMode', 'auto',...
    'PaperSize', [],...
    'Position', [],...
    'Resize', 'on',...
    'Size', [],...
    'Tag', 'WindowObject',...
    'Units', 'pixels',...
    'Visible', 'on');
assignInputs(inStruct, varargin, 'structOnly',...
    'compatibility', {'Color', 'background', 'backgroundColor';...
                      'Colorbar', 'cbar', [];...
                      'Colormap', 'cmap', 'map';...
                      'MenuBar', 'menu', 'mbar';...
                      'NumberTitle', 'number', 'title';...
                      'Resize', 'resizable', [];...
                      'Size', 'figureSize', 'figSize';...
                      'Position', 'moveTo', 'figurePosition';...
                      'Visible', 'visibleFig', 'visibleFigs'});

% Change input background color strings to RGB
if ~isempty(inStruct.Color) && ischar(inStruct.Color)
    inStruct.Color = str2rgb(inStruct.Color);
end

% Allow flexibility in certain property value names
if istrue(inStruct.MenuBar)
    inStruct.MenuBar = 'figure';
else
    inStruct.MenuBar = 'none';
end



%% Generate a Figure & Capture the Handle
if ~isempty(inStruct.FigureNumber)
    % Make sure the figure being generated is unique
    figNum = inStruct.FigureNumber;
    while ishandle(figNum)
        figNum = figNum + 1;
    end
    figHandle = figure(figNum);
    windowHandle.FigureHandle = figHandle;
else
    figHandle = figure;
    windowHandle.FigureHandle = figHandle;
end

% Set the size of the window, then position
newFigPos = get(windowHandle.FigureHandle, 'OuterPosition');
if ~isempty(inStruct.Size)
    if ischar(inStruct.Size)
        newFigPos = windowHandle.translate(inStruct.Size, newFigPos);
    elseif length(inStruct.Size) == 4
        newFigPos = inStruct.Size;
    else
        newFigPos(3:4) = inStruct.Size;
    end
end
if ~isempty(inStruct.Position)
    if ischar(inStruct.Position)
        newFigPos = windowHandle.translate(inStruct.Position, newFigPos);
    elseif length(inStruct.Position) == 4
        newFigPos = inStruct.Position;
    else
        newFigPos(1:2) = inStruct.Position;
    end
end    
set(windowHandle.FigureHandle, 'OuterPosition', newFigPos);

% Fix overlapping windows
if ~isempty(inStruct.FigureNumber)
    if figNum ~= inStruct.FigureNumber
        outerPos = get(figNum-1, 'OuterPosition');
        whOuterPos = get(windowHandle.FigureHandle, 'OuterPosition');        
        whOuterPos(2) = outerPos(2) - whOuterPos(4);
        set(windowHandle.FigureHandle, 'OuterPosition', whOuterPos);
    end
end

% Remove unnecessary fields from the input structure
inStruct = rmfield(inStruct, {'FigureNumber', 'Size', 'Position'});



%% Assign Input Values to Object Properties
% Get the property names to be changed
propNames = fieldnames(inStruct);

% Change the property values
for i = 1:length(propNames)
    switch lower(propNames{i})
        case 'colorbar'
            if istrue(inStruct.Colorbar)
                windowHandle.Colorbar = colorbar;
            end
        otherwise
            if ~isempty(inStruct.(propNames{i}))
                set(windowHandle.FigureHandle, propNames{i}, inStruct.(propNames{i}));
            end
    end
end

% Freeze the window size, if called for
if ~isempty(inStruct.Resize)
    set(windowHandle.FigureHandle, 'Resize', inStruct.Resize);
end