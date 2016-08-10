% WINDOW - Creates an easily customizable figure window.
%
%   This class automates some of the more tedious work associated with figure building. It allows for easy window resizing
%   and placement on the screen by providing a number of common presets. It also contains several fields for storing object
%   handles and data that are frequently used in conjunction with figures.
%
%	Window Properties:
%		Axes		- A reference to the Axes object used for plotting in the window.
%		Background	- The background color of the window.
%		Colorbar	- A reference to the Colorbar object displayed within the window.
%		Colormap	- The color mapping used to display colorized data.
%		Data		- A general-purpose field used for storing data related to window contents.
%       Handle      - The underlying figure window that is wrapped by this class.
%		Name		- The string displayed in the window title bar.
%		Patch		- Handles to various Patch objects that exist within the window.
%		Position	- The position of the lower left window corner, [X, Y] in pixels, on the computer screen.
%       Resize      - A Boolean indicating whether the window can be resized by the user.
%		Size		- The size of the window, [Width, Height] in pixels, on the computer screen.
%		Text		- Handles to various Text objects that exist within the window.
%
%	Window Constructor:
%		Window		- Constructs a new Window object.
%
%	Window Methods:
%		Close		- Closes a window and deletes the associated handle variable in the calling workspace.
%		ToBitmap	- Captures an image of all current window contents in the form of a Bitmap object.
%		ToFigure	- Converts a Window object reference into a native MATLAB figure handle.
%
%	See also: AXES, FIGURE, MONTAGE, PROGRESS

%% CHANGELOG
%   Written by Josh Grooms on 20130205
%       20130801:   Removed a number of redundant properties in order to make this object more lightweight. Major  overhaul
%					of object functionality. Now windowObj is more of a wrapper for the native FIGURE objects. Removed old
%					changelog entries (see SVN for the complete list)
%       20130803:   Moved GET to a separate function & improved its functionality. Renamed the initialization function  to
%					DRAWWINDOW to prevent conflict with subclasses.
%       20140716:   Major reorganization of this class. Removed the ability to set window sizes and positions using strings
%					and replaced them with enumerations for better control. Removed the general GET and SET overloads as well
%					as the ability to interface directly with the wrapped figure handle through this class.
%       20140805:   Implemented a wrapping property and get/set methods for window background color. Removed the DISP
%                   function now that native figure properties are no longer accessible through this class.
%       20140807:   Implemented a wrapping property and get/set methods for the window title bar name string.
%       20140828:   Implemented a property controlling the figure color mapping.
%       20141110:   Changed the Window class to open a full screen window by default, since this is almost universally how
%					it's used.
%		20141121:	Rewrote the constructor method to use the new input assignment system and to get rid of the externally
%					defined Initialize function.
%		20141210:	Implemented a method that converts a window object into a native MATLAB figure handle.
%		20141212:	Changed the name of "close" to "Close" for consistency with all my other class methods and because I keep
%					making that typo in code that I write. Fixed a bug that occurred when trying to create a figure with a
%					specific figure number and with a close function callback assignment.
%		20150128:	Added a new property "Patch" to hold patch graphics object references.
%		20150507:	Overhauled the class documentation to summarize all of the properties and methods that are available.
%		20150727:	Removed restrictions on the Background and Colormap properties to be Color data structures. These
%					introduced new dependencies to the class and were not intuitive to anyone other than me. Also, the Color
%					class itself currently introduces a lot of overhead to any processing, which definitely isn't needed in
%					the HG2 graphics system. However, I've left in the code that maintains compatibility with that class.
%       20150824:   Implemented a wrapper property for controlling the resizability of MATLAB figures.
%       20160810:   Implemented an accessor for getting the underlying figure window. Originally, this wasn't included in order
%                   to prevent tampering with settings that this class wouldn't be able to observe. However, not having access
%                   gets in the way more often than it helps.



%% CLASS DEFINITION
classdef Window < handle & Entity



    %% DATA
    properties (Dependent)
        Background				% The background color of the window.
        Colormap				% The color mapping used to display colorized data.
        Handle                  % The handle to the underlying figure window wrapped by this object.
        Name        @char       % The string displayed in the window title bar.
        Position                % The position of the window on-screen in pixels.
        Resize                  % A Boolean indicating whether this window can be resized by the user.
        Size                    % The size of the window on-screen in pixels.
    end

    properties (SetObservable, AbortSet)
        Axes                    % An axes object customized for this window.
        Colorbar                % A color bar object customized for this window.
        Data                    % Any data displayed in the window's axes.
		Patch					% Handles to various patch objects that exist in the window.
        Text                    % Handles to various text objects that exist in the window.
    end

    properties (Hidden, Access = protected)
        FigureHandle            % The numeric figure handle this object controls.
        Listeners               % Handles of listeners for events & property changes.
        PositionEnum            % The screen position where the window should be located.
        SizeEnum                % The screen size that the window should be.
    end

    properties (Hidden, Dependent, Access = protected)
        Rectangle               % The client rectangle specifying the size & position of the window.
	end



	%% PROPERTIES
	methods
		% Get methods
        function C = get.Background(H)
            C = get(H.FigureHandle, 'Color');
        end
		function C = get.Colormap(H)
            C = get(H.FigureHandle, 'Colormap');
        end
        function h = get.Handle(H)
            h = H.FigureHandle;
        end
        function s = get.Name(H)
            s = get(H.FigureHandle, 'Name');
        end
        function p = get.Position(H)
            p = get(H.FigureHandle, 'OuterPosition');
            p = p(1:2);
        end
		function r = get.Rectangle(H)
            r = get(H.FigureHandle, 'OuterPosition');
        end
        function b = get.Resize(H)
            b = get(H.FigureHandle, 'Resize');
        end
		function s = get.Size(H)
            s = get(H.FigureHandle, 'OuterPosition');
            s = s(3:4);
        end

        % Set methods
        function set.Background(H, color)
            if isa(color, 'Color'); color = color.ToArray(); end
            set(H.FigureHandle, 'Color', color);
        end
        function set.Colormap(H, cmap)
			if isa(cmap, 'Color'); cmap = cmap.ToMatrix(); end
            set(H.FigureHandle, 'Colormap', cmap);
        end
        function set.Name(H, name)
            set(H.FigureHandle, 'Name', name);
        end
        function set.Position(H, position)
            if isa(position, 'WindowPositions')
                H.Rectangle(1:2) = position.ToPixels(H.Size);
                H.PositionEnum = position;
            elseif isnumeric(position)
                if isvector(position) && length(position) == 2
                    H.Rectangle(1:2) = position;
                else
                    error('Window positions can only be specified using two-element vectors or enumerator shortcuts.');
                end
            end
        end
        function set.Rectangle(H, rectangle)
            set(H.FigureHandle, 'OuterPosition', rectangle);
        end
        function set.Resize(H, resize)
            if istrue(resize); resize = 'on';
            else resize = 'off'; end
            set(H.FigureHandle, 'Resize', resize);
        end
        function set.Size(H, size)
            if isa(size, 'WindowSizes')
                H.Rectangle(3:4) = size.ToPixels;
                H.SizeEnum = size;
            elseif isnumeric(size)
				assert(isvector(size) && length(size) == 2,...
					'Window sizes can only be specified using two-element vectors or enumerator shortcuts.');
                H.Rectangle(3:4) = size;
            else
                error('Window sizes can only be specified using two-element vectors or enumerator shortcuts.');
            end
            if ~isempty(H.PositionEnum); H.Position = H.PositionEnum; end
		end
	end



    %% CONSTRUCTORS
    methods
		function W = Window(varargin)
		% WINDOW - Construct a window object with multiple features.

			function Defaults
				Background			= [1, 1, 1];
				Colormap			= jet(256);
				FigureNumber		= [];
				InvertHardcopy		= 'off';
				MenuBar				= 'none';
				Name				= '';
				NumberTitle			= 'off';
				PaperPositionMode	= 'auto';
				PaperSize			= [8.5, 11];
				Position			= WindowPositions.CenterCenter;
				Resize				= 'on';
				Size				= WindowSizes.FullScreen;
				Tag					= 'WindowObject';
				Units				= 'pixels';
				Visible				= 'on';
			end
			assign(@Defaults, varargin);

			W.CreateFigure(FigureNumber);

			W.Background	= Background;
			W.Colormap		= Colormap;
			W.Name			= Name;
			W.Position		= Position;
			W.Size			= Size;

			set(W.FigureHandle, 'InvertHardcopy', InvertHardcopy);
			set(W.FigureHandle, 'MenuBar', MenuBar);
			set(W.FigureHandle, 'NumberTitle', NumberTitle);
			set(W.FigureHandle, 'PaperPositionMode', PaperPositionMode);
			set(W.FigureHandle, 'PaperSize', PaperSize);
			set(W.FigureHandle, 'Resize', Resize);
			set(W.FigureHandle, 'Tag', Tag);
			set(W.FigureHandle, 'Units', Units);
			set(W.FigureHandle, 'Visible', Visible);
        end
    end



    %% UTILITIES
	methods (Hidden, Access = protected)
		function CreateFigure(H, figNum)
		% CREATEFIGURE - Creates a native MATLAB figure and captures a reference to it.
			if (isempty(figNum))
				H.FigureHandle = figure('CloseRequestFcn', @H.Close);
			else
				while (ishandle(figNum))
					figNum = figNum + 1;
				end
				H.FigureHandle = figure(figNum);
				set(H.FigureHandle, 'CloseRequestFcn', @H.Close);
			end
		end
	end

    methods
		function Close(W, varargin)
		% CLOSE - Closes a window and invalidates the associated handle variable.
            delete(W.FigureHandle);
        end
        function Store(W, filename)

			DEPRECATED Window.Save
            saveas(W.FigureHandle, filename);
		end

		function B = ToBitmap(W)
		% TOBITMAP - Captures an image of all current window contents in the form of a bitmap object.
			f = getframe(W.FigureHandle);
			B = Bitmap.FromRGB(f.cdata);
		end
		function F = ToFigure(H)
		% TOFIGURE - Converts a window object into a native MATLAB figure handle.
			F = H.FigureHandle;
		end
	end



end
