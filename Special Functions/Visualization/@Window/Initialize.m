function Initialize(H, varargin)
%DRAWWINDOW - Initializes the figure window with input properties.
%
%   WARNING: This method is for internal class use only and is not meant to be called directly.

%% CHANGELOG
%   Written by Josh Grooms on 20130206
%       20130801:   Updated method name for consistency with other objects. Major overhaul of object to make it more 
%                   lightweight and easy to deal with. Removed the massive changelog (see SVN for the complete listing).
%       20130803:   Removed presets altogether (these should go in their respective subclass definintions). Wrote a 
%                   separate function for converting strings to RGB values.
%       20140716:   Updated this function to work with the new position and size enumerations for this class. 



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
    'NumberTitle', 'off',...
    'PaperPositionMode', 'auto',...
    'PaperSize', [],...
    'Position', WindowPositions.CenterCenter,...
    'Resize', 'on',...
    'Size', WindowSizes.Default,...
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
    H.FigureHandle = figHandle;
else
    figHandle = figure;
    H.FigureHandle = figHandle;
end

% Set the size of the window, then position
if ~isempty(inStruct.Size)
    H.Size = inStruct.Size;
end
    
if ~isempty(inStruct.Position)
    H.Position = inStruct.Position;
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
                H.Colorbar = colorbar;
            end
        otherwise
            if ~isempty(inStruct.(propNames{i}))
                set(H.FigureHandle, propNames{i}, inStruct.(propNames{i}));
            end
    end
end

% Freeze the window size, if called for
if ~isempty(inStruct.Resize)
    set(H.FigureHandle, 'Resize', inStruct.Resize);
end