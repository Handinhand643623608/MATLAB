classdef WindowPositions
%WINDOWPOSITIONS - An enumeration of common window positions.

%% CHANGELOG
%   Written by Josh Grooms on 20140717



    %% Window Position Enumerators
    enumeration
        
        CenterCenter
        CenterLeft
        CenterRight
        LowerCenter
        LowerLeft
        LowerRight
        UpperCenter
        UpperLeft
        UpperRight
        
    end
    
    
    
    
    %% Enumeration Utilities
    methods
        % Convert position enumerators to pixel values
        function position = ToPixels(enum, size)
            %TOPIXELS - Convert a window position enumerator into X and Y pixel values.
            
            % Account for the Windows taskbar
            taskbarSize = 40;
            screenSize = get(0, 'ScreenSize');
            screenSize = screenSize(3:4);
            
            position = zeros(1, 2);
            
            switch enum
                
                case WindowPositions.CenterCenter
                    position(1) = 1 + round((screenSize(1) - size(1))/2);
                    position(2) = 1 + taskbarSize + round((screenSize(2) - taskbarSize - size(2))/2);
                case WindowPositions.CenterLeft
                    position(1) = 1;
                    position(2) = 1 + taskbarSize + round((screenSize(2) - taskbarSize - size(2))/2);
                case WindowPositions.CenterRight
                    position(1) = screenSize(1) - size(1);
                    position(2) = 1 + taskbarSize + round((screenSize(2) - taskbarSize - size(2))/2);
                case WindowPositions.LowerCenter
                    position(1) = 1 + round((screenSize(1) - size(1))/2);
                    position(2) = 1 + taskbarSize;
                case WindowPositions.LowerLeft
                    position(1) = 1;
                    position(2) = 1 + taskbarSize;
                case WindowPositions.LowerRight
                    position(1) = screenSize(1) - size(1);
                    position(2) = 1 + taskbarSize;
                case WindowPositions.UpperCenter
                    position(1) = 1 + round((screenSize(1) - size(1))/2);
                    position(2) = screenSize(2) - size(2) + 1;
                case WindowPositions.UpperLeft
                    position(1) = 1;
                    position(2) = screenSize(2) - size(2) + 1;
                case WindowPositions.UpperRight
                    position(1) = screenSize(1) - size(1);
                    position(2) = screenSize(2) - size(2) + 1;
                    
            end
        end
    end
end
        