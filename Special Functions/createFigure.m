function varargout = createFigure(varargin)
%CREATEFIGURE
% 
%   Syntax:
% 
% 
%   OUTPUTS:
%   ('figHandle'):
% 
%   ('axesHandle'):
% 
%   PROPERTY NAMES:
%   ('backgroundColor'):
% 
%   ('colorMap'):
% 
%   ('editFigure'):
% 
%   ('figureSize'):
% 
%   ('figurePosition'):
% 
%   ('numFigs'):
% 
%   ('plotToMonitor'):
% 
%   ('visible'):
% 
%   Written by Josh Grooms on 20130124
%       20130126 - Updated to account for outside changes to figure units when updating existing
%                  figures.


inStruct = struct(...
    'backgroundColor', [0.8 0.8 0.8],...    
    'colorMap', jet(64),...
    'editFigure', [],...
    'figureSize', 'halfScreen',...
    'figurePosition', 'center-center',...
    'numFigs', 1,...
    'plotToMonitor', 'primary',...
    'visible', 'on');
assignInputs(inStruct, varargin, {'figurePosition'}, 'lower(varPlaceholder)');


%% Choose the Monitor to Create Figure(s) In
% Get a list of the monitors available
allMonitors = get(0, 'MonitorPositions');

% Choose the monitor based on defaults or user input & get absolute position
if strcmpi(plotToMonitor, 'primary')
    screenPositions = get(0, 'screenSize');
else
    switch plotToMonitor
        case 'left'
            screenPositions = allMonitors(1, :);
            screenPositions(1:2) = screenPositions(1:2) - 1;
        case {'top', 'upper'}
            screenPositions = allMonitors(3, :);
            screenPositions(1:2) = 2 - screenPositions(1:2);
    end
end

% Get the dimensions of the chosen monitor
screenHeight = (screenPositions(4) - screenPositions(2)) + 1;
screenWidth = (screenPositions(3) - screenPositions(1)) + 1;
screenResolution = [screenWidth screenHeight];


%% Adjust the Figure Size to the Defaults or User Input
if ischar(figureSize)
    switch figureSize

        case 'halfScreen'
            % Preserve the shorter of the screen dimensions
            newSize = screenResolution;
            maxDimVal = max(screenResolution);
            newSize(screenResolution == maxDimVal) = round(0.5*maxDimVal);
            cbarWidth = 0.0282;

        case 'quarterScreen'
            newSize = round(0.5.*screenResolution);
            cbarWidth = 0.0282;

        case 'fullScreen'
            newSize = [screenWidth screenHeight];
            cbarWidth = 0.0139;

        otherwise
            error('Unknown input given for parameter ''figureSize''. Check the documentation for help');
    end
elseif isnumeric(figureSize) && length(figureSize) == 2
    newSize = figureSize;
else
    error('Unknown input given for parameter ''figureSize''. Check the documentation for help');
end
        

%% Adjust the Figure Position to the Defaults or User Input
% Figure out where the user wants the plot to go
if ischar(figurePosition)
    newPosition = regexpi(figurePosition, '([^-]*)', 'tokens');
    newPosition = cat(2, newPosition{:});

    % Account for syntax errors
    if sum(strcmpi(newPosition{1}, {'left', 'right'})) || sum(strcmpi(newPosition{2}, {'upper', 'top', 'lower', 'bottom'}))
        newPosition = flipdim(newPosition, 2);
    end

    % Create the coordinates
    switch newPosition{1}
        case {'upper', 'top'}
            newVertical = screenPositions(2) + screenHeight - newSize(2);

        case {'lower', 'bottom'}
            newVertical = screenPositions(2);

        case {'center', 'middle'}
            newVertical = screenPositions(2) + round((screenHeight - newSize(2))/2);
    end

    switch newPosition{2}
        case 'left'
            newHorizontal = screenPositions(1);

        case 'right'
            newHorizontal = screenPositions(1) + screenWidth - newSize(1);

        case {'center', 'middle'}
            newHorizontal = screenPositions(1) + round((screenWidth - newSize(1))/2);
    end

elseif isnumeric(figurePosition)
    newHorizontal = figurePosition(1);
    newVertical = figurePosition(2);
else
    error('Unknown input given for parameter ''figurePosition''. Check the documentation for help');
end

newPosition = [newHorizontal newVertical];


%% Create the Figure(s)
if isempty(editFigure)
    figHandle = zeros(numFigs, 1);
    axesHandle = zeros(numFigs, 1);
    for i = 1:numFigs
        figHandle(i) = figure;
        set(figHandle,...
            'Color', backgroundColor,...
            'Colormap', colorMap,...
            'OuterPosition', [newPosition newSize],...
            'Visible', visible);
        
        axesHandle(i) = gca;
    end
else
    % Account for possible changes to figure units
    oldUnits = get(editFigure, 'Units');
    set(editFigure, 'Units', 'pixels');
    set(editFigure,...
        'Color', backgroundColor,...
        'Colormap', colorMap,...
        'OuterPosition', [newPosition newSize],...
        'Visible', visible);
    set(editFigure, 'Units', oldUnits);
    
    % Restore colorbar original x-dimension, if necessary
    cbarHandle = findobj(editFigure, 'Tag', 'Colorbar');
    if ~isempty(cbarHandle)
        tempUnits = get(cbarHandle, 'Units');
        set(cbarHandle, 'Units', 'normalized');
        tempPos = get(cbarHandle, 'Position');
        tempPos(3) = cbarWidth;
        set(cbarHandle, 'Position', tempPos);
        set(cbarHandle, 'Units', tempUnits);
    end
        
    figHandle = editFigure;
    axesHandle = get(editFigure, 'CurrentAxes');
end


% Assign outputs
assignOutputs(nargout, figHandle, axesHandle);
            
    
    
    