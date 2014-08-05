classdef Window < hgsetget
%WINDOW - Creates an easily customizable figure window.
%   This class automates some of the more tedious work associated with figure building. It allows for easy window
%   resizing and placement on the screen by providing a number of common presets. It also contains several fields for
%   storing object handles and data that are frequently used in conjunction with figures. 

%% CHANGELOG
%   Written by Josh Grooms on 20130205
%       20130801:   Removed a number of redundant properties in order to make this object more lightweight. Major 
%                   overhaul of object functionality. Now windowObj is more of a wrapper for the native FIGURE objects.
%                   Removed old changelog entries (see SVN for the complete list)
%       20130803:   Moved GET to a separate function & improved its functionality. Renamed the initialization function 
%                   to DRAWWINDOW to prevent conflict with subclasses.
%       20140716:   Major reorganization of this class. Removed the ability to set window sizes and positions using
%                   strings and replaced them with enumerations for better control. Removed the general GET and SET
%                   overloads as well as the ability to interface directly with the wrapped figure handle through this
%                   class. 
%       20140805:   Implemented a wrapping property and get/set methods for window background color. Removed the DISP
%                   function now that native figure properties are no longer accessible through this class.
    
    

    %% Window Object Properties
    properties (Dependent)
        Color                   % The background color of the window.
        Position                % The position of the window on-screen in pixels.
        Size                    % The size of the window on-screen in pixels.
    end
    
    properties (SetObservable, AbortSet)
        Axes                    % An axes object customized for this window.
        Colorbar                % A color bar object customized for this window.
        Data                    % Any data displayed in the window's axes.
        Text                    % Handles to various text objects that exist in the window.
    end

    properties (Access = protected, Hidden)
        FigureHandle            % The numerical figure handle this object controls.
        Listeners               % Handles of listeners for events & property changes.
        PositionEnum            % The screen position where the window should be located.
        SizeEnum                % The screen size that the window should be.
    end
    
    properties (Access = protected, Dependent, Hidden)
        Rectangle               % The client rectangle specifying the size & position of the window.
    end
    
    
    
    %% Constructor Method
    methods 
        function H = Window(varargin)
            %WINDOW - Construct a window object with multiple features.
            Initialize(H, varargin{:});
        end
    end

    
    
    %% Overloaded MATLAB Methods
    methods

        function close(H, varargin)
            %CLOSE - Close the window and delete the associated variable in the calling workspace.
            delete(H.FigureHandle)
            evalin('caller', ['clear ' inputname(1)]);
        end
        
        % Get methods
        function color      = get.Color(H)
            color = get(H.FigureHandle, 'Color');
        end
        function position   = get.Position(H)
            position = get(H.FigureHandle, 'OuterPosition');
            position = position(1:2);
        end
        function rectangle  = get.Rectangle(H)
            rectangle = get(H.FigureHandle, 'OuterPosition');
        end
        function size       = get.Size(H)
            size = get(H.FigureHandle, 'OuterPosition');
            size = size(3:4);
        end
        
        % Set methods
        function set.Color(H, color)
            if isa(color, 'Color')
                color = color.ToArray;
            end    
            set(H.FigureHandle, 'Color', color);
        end
        function set.Position(H, position)
            if isa(position, 'WindowPositions')
                H.Rectangle(1:2) = position.ToPixels(H.Size);
                H.PositionEnum = position;
            elseif isnumeric(position)
                if isvector(position) && length(position) == 2
                    H.Rectangle(1:2) = position;
                else
                    error('Window positions can only be specified using two-element vectors or string shortcuts.');
                end
            end
        end
        function set.Rectangle(H, rectangle)
            set(H.FigureHandle, 'OuterPosition', rectangle);
        end
        function set.Size(H, size)
            if isa(size, 'WindowSizes')
                H.Rectangle(3:4) = size.ToPixels;
                H.SizeEnum = size;
            elseif isnumeric(size)
                if isvector(size) && length(size) == 2
                    H.Rectangle(3:4) = size;
                else
                    error('Window sizes can only be specified using two-element vectors or string shortcuts.');
                end
            end
            if ~isempty(H.PositionEnum); H.Position = H.PositionEnum; end
        end
        
    end
    
    
    
    %% Class-Specific Methods
    methods (Access = protected)
        % Add input property values to the object
        Initialize(windowHandle, varargin)
    end
    
    
   
end



            