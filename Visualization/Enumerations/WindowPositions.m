% WINDOWPOSITIONS - An enumeration of common window positions on a computer monitor.
%
%	WindowPositions Enumerators:
%		CenterCenter	- The very center of the screen.
%		CenterLeft		- The middle of the left side of the screen.
%		CenterRight		- The middle of the right side of the screen.
%		LowerCenter		- The middle of the lower side of the screen.
%		LowerLeft		- The lower left corner of the screen.
%		LowerRight		- The lower right corner of the screen.
%		UpperCenter		- The middle of the upper side of the screen.
%		UpperLeft		- The upper left corner of the screen.
%		UpperRight		- The upper right corner of the screen.
%
%	WindowPositions Methods:
%		ToPixels		- Converts a WindowPositions enumerator into X and Y pixel coordinates given the size of the window. 
%
%	See also: WINDOWSIZES

%% CHANGELOG
%   Written by Josh Grooms on 20140717
%		20150509:	Overhauled teh class documentation to summarize all of the properties and methods that are available.



%% CLASS DEFINITION
classdef WindowPositions



    %% ENUMERATORS
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
    
    
    
    
    %% UTILITIES
    methods
        function sp = ToPixels(P, sz)
		% TOPIXELS - Converts a WindowPositions enumerator into X and Y pixel coordinates given the size of the window.
		%
		%	SYNTAX:
		%		sp = P.ToPixels(sz)
		%
		%	OUTPUT:
		%		sp:		[ 1 x 2 INTEGERS ]
		%				A two-element vector specifying the [X, Y] position in pixels of the lower left corner of a window
		%				relative to the lower left corner of the computer monitor.
		%	
		%	INPUTS:
		%		P:		WINDOWPOSITIONS
		%				A WindowPositions enumerator to be converted into pixel values.
		%
		%		sz:		WINDOWSIZES or [ 1 x 2 INTEGERS ]
		%				A WindowSizes enumerator or two-element vector specifying the [WIDTH, HEIGHT] of the window in
		%				pixels.
		%
		%	See also: WINDOWSIZES.TOPIXELS
            
			% Account for the Windows taskbar
            taskbarSize = 40;
            screenSize = get(0, 'ScreenSize');
            screenSize = screenSize(3:4);
            
			if (isa(sz, 'WindowSizes')); sz = sz.ToPixels(); end
			
            sp = zeros(1, 2);
            switch P
                
                case WindowPositions.CenterCenter
                    sp(1) = 1 + round((screenSize(1) - sz(1))/2);
                    sp(2) = 1 + taskbarSize + round((screenSize(2) - taskbarSize - sz(2))/2);
                case WindowPositions.CenterLeft
                    sp(1) = 1;
                    sp(2) = 1 + taskbarSize + round((screenSize(2) - taskbarSize - sz(2))/2);
                case WindowPositions.CenterRight
                    sp(1) = screenSize(1) - sz(1);
                    sp(2) = 1 + taskbarSize + round((screenSize(2) - taskbarSize - sz(2))/2);
                case WindowPositions.LowerCenter
                    sp(1) = 1 + round((screenSize(1) - sz(1))/2);
                    sp(2) = 1 + taskbarSize;
                case WindowPositions.LowerLeft
                    sp(1) = 1;
                    sp(2) = 1 + taskbarSize;
                case WindowPositions.LowerRight
                    sp(1) = screenSize(1) - sz(1);
                    sp(2) = 1 + taskbarSize;
                case WindowPositions.UpperCenter
                    sp(1) = 1 + round((screenSize(1) - sz(1))/2);
                    sp(2) = screenSize(2) - sz(2) + 1;
                case WindowPositions.UpperLeft
                    sp(1) = 1;
                    sp(2) = screenSize(2) - sz(2) + 1;
                case WindowPositions.UpperRight
                    sp(1) = screenSize(1) - sz(1);
                    sp(2) = screenSize(2) - sz(2) + 1;
                    
            end
        end
	end
	
	
	
end
        