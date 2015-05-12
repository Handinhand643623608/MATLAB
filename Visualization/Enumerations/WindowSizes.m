%WINDOWSIZES - An enumeration of common window sizes on a computer monitor.
%
%	WindowSizes Enumerators:
%		Default			- The default figure size used by MATLAB (Width = 576, Height = 513).
%		FullScreen		- A window that fills the entire screen, excluding the Windows taskbar.
%		HalfScreen		- A window that fills half of the screen.
%		QuarterScreen	- A window that fills one quarter of the screen.
%
%	WindowSizes Methods:
%		ToPixels		- Converts a WindowSizes enumerator into width and height pixel values.

%% CHANGELOG
%   Written by Josh Grooms on 20140716
%		20150509:	Overhauled the class documentation to summarize all of the properties and methods that are available.



%% CLASS DEFINITION
classdef WindowSizes




    %% ENUMERATORS
    enumeration
        Default         % The default figure size used by MATLAB (Width = 576, Height = 513).
        FullScreen      % A window that fills the entire screen, excluding the Windows taskbar.
        HalfScreen		% A window that fills half of the screen.
        QuarterScreen	% A window that fills one quarter of the screen.
    end
    
    
    
    %% Enumerator Conversion Methods
    methods
        function sz = ToPixels(S)
		% TOPIXELS - Convert a WindowSizes enumerator into width and height pixel values.
            
            % Account for the Windows task bar size
            taskbarSize = 40;
            screenSize = get(0, 'ScreenSize');
            screenSize = screenSize(3:4);
            screenSize(2) = screenSize(2) - taskbarSize;
            
            % Create & return a size vector
            switch S
                case WindowSizes.Default
                    sz = [576, 512];
                case WindowSizes.FullScreen
                    sz = screenSize;
                case WindowSizes.HalfScreen
                    sz = screenSize;
                    maxSize = max(screenSize);
                    sz(sz == maxSize) = round(0.5*maxSize);
                case WindowSizes.QuarterScreen
                    sz = round(0.5.*screenSize);
            end
        end
	end

	

end

