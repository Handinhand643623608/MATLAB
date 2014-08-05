function outData = translate(inStr, figPos)
%TRANSLATE Translates sizing & positioning strings into coordinates.
%   This function translates ease-of-use strings representing how to size and position a figure window into their
%   respective on screen coordinates. This function is monitor-aware and should work with screens of any resolution and
%   aspect ratio.
%
%   SYNTAX:
%   outData = translate(inStr)
%
%   OUTPUT:
%   outData:    [INTEGER, INTEGER] or [INTEGER, INTEGER, INTEGER, INTEGER]
%               A set of computer monitor coordinates converted from the user's input string(s). These are the
%               coordinates where the figure window will either be moved to or resized to. If a size translation is
%               called for, this output will contain 4 elements (two position elements are also included to ensure the
%               window stays on-screen). Otherwise, the output will contain two position elements only.
%
%   INPUT:
%   inStr:      STRING
%               A string that represents where the user would like the figure window placed or how large to make the
%               figure window. If inputting a string for location, two words joined by a hyphen must be supplied. Size
%               strings are only one word.
%               OPTIONS:
%                   POSITION STRINGS: (any from either side joined by a hyphen)
%                       'upper'           'left'
%                       'center'    -     'center'
%                       'lower'           'right'
%                   
%                   SIZE STRINGS:
%                       'default'
%                       'halfscreen'
%                       'quarterscreen'
%                       'fullscreen'
%
%   figPos:     [INTEGER, INTEGER, INTEGER, INTEGER]
%               A four-element vector specifying where the window is currently placed and how big it is. This is the
%               OUTERPOSITION property of the figure.



%% CHANGELOG
%   Written by Josh Grooms on 20130801
%       20130811:   Bug fix for center window positioning while at fullscreen size.



%% Initialize
% Initialize variables
szTaskbar = 40;

% Determine Current Monitor Resolution
screenResolution = get(0, 'screensize');
screenResolution = screenResolution(3:4);

% Get the current window position & desired position string
inputStrings = regexpi(inStr, '(.*)-(.*)', 'tokens');



%% Translate the Size/Position String into Coordinates
switch isempty(inputStrings)
    case true
        switch lower(inStr)
            case 'default'
                % Restore to default size & position
                tempMeta = parameters(windowObj);
                newPosition = tempMeta.Position;
                newSize = tempMeta.Size;
            
            case {'halfscreen', 'half'}
                % Preserve the shorter of the screen dimensions
                newSize = screenResolution(1:2);
                newSize(1) = round(0.5*max(screenResolution));
                newSize(2) = newSize(2) - szTaskbar;
                newPosition = [newSize(1) 1+szTaskbar];
            
            case {'quarterscreen', 'quarter'}
                % Set to quarter screen size
                newSize = round(0.5.*[screenResolution(1) screenResolution(2)-szTaskbar]);
                newPosition = screenResolution - newSize;
            
            case {'fullscreen', 'full'}
                % Set to full screen size
                newSize = [screenResolution(1) screenResolution(2)-szTaskbar-1];
                newPosition = [1 szTaskbar+1];
            
            otherwise
                % Error checking
                error('Unknown input given for position or size parameters. Check the documentation for help');
        end
        outData = [newPosition, newSize];
    
    otherwise
        
        newSize = figPos(3:4);
        newPosition = cat(2, inputStrings{:});
        
        % Account for syntax errors
        if any(strcmpi(newPosition{1}, {'left', 'right'})) || any(strcmpi(newPosition{2}, {'upper', 'top', 'lower', 'bottom'}))
            newPosition = flipdim(newPosition, 2);
        end
        
        % Create the vertical coordinates
        switch lower(newPosition{1})
            case {'upper', 'top', 'north'}
                newVertical = screenResolution(2) - newSize(2) + 1;
            case {'lower', 'bottom', 'south'}
                newVertical = 1 + szTaskbar;
            case {'center', 'middle'}
                newVertical = 1 + szTaskbar + round((screenResolution(2) - szTaskbar - newSize(2))/2);
        end
        
        % Create the horizontal coordinates
        switch lower(newPosition{2})
            case {'left', 'west'}
                newHorizontal = 1;
            case {'right', 'east'}
                newHorizontal = screenResolution(1) - newSize(1);
            case {'center', 'middle'}
                newHorizontal = 1 + round((screenResolution(1) - newSize(1))/2);
        end
        outData = [newHorizontal, newVertical, newSize];
end