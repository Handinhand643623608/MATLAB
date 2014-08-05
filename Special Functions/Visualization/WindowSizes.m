classdef WindowSizes
%WINDOWSIZES - An enumeration of common window sizes.


%% CHANGELOG
%   Written by Josh Grooms on 20140716



    %% Window Size Enumerations
    enumeration
        Default         
        FullScreen      
        HalfScreen
        QuarterScreen
    end
    
    
    
    %% Enumerator Conversion Methods
    methods
        % Convert screen size enumerations into vectors of pixel values
        function size = ToPixels(enum)
            %TOPIXELS - Convert a window size enumerator into height and width pixel values.
            
            % Account for the Windows task bar size
            taskbarSize = 40;
            screenSize = get(0, 'ScreenSize');
            screenSize = screenSize(3:4);
            screenSize(2) = screenSize(2) - taskbarSize;
            
            % Create & return a size vector
            switch enum
                case WindowSizes.Default
                    size = [576, 512];
                case WindowSizes.FullScreen
                    size = screenSize;
                case WindowSizes.HalfScreen
                    size = screenSize;
                    maxSize = max(screenSize);
                    size(size == maxSize) = round(0.5*maxSize);
                case WindowSizes.QuarterScreen
                    size = round(0.5.*screenSize);
            end
        end
    end


end

