classdef windowObj < hgsetget
%WINDOWOBJ Creates an easily customizable figure window.
%   This object automates a lot of the more difficult and tedious work associated with figure
%   and GUI building. This includes window resizing, figure/GUI element placement, and settings
%   associated with saving images.



%% CHANGELOG
%   Written by Josh Grooms on 20130205
%       20130801:   Removed a number of redundant properties in order to make this object more
%                   lightweight. Major overhaul of object functionality. Now windowObj is more
%                   of a wrapper for the native FIGURE objects. Removed old changelog entries
%                   (see SVN for the complete list)
%       20130803:   Moved GET to a separate function & improved its functionality. Renamed the
%                   initialization function to DRAWWINDOW to prevent conflict with subclasses.
    
    

    %% Window Object Properties
    properties (SetObservable, AbortSet)
        Axes                    % An axes object customized for this window.
        Colorbar                % A color bar object customized for this window.
        Data                    % Any data displayed in the window's axes        
        FigureHandle            % The numerical figure handle this object controls.
        Listeners               % Handles of listeners for events & property changes.
        Monitor                 % Which monitor the window is being displayed on.
        Text                    % Handles to various text objects that exist in the window
    end

    
    
    %% Constructor Method
    methods 
        function windowHandle = windowObj(varargin)
            %WINDOWOBJ Construct a window object with multiple features.            
            drawWindow(windowHandle, varargin{:});
        end
    end

    
    
    %% Public Methods
    methods
        % Overload the default delete method (close the figure first)
        function close(windowHandle, varargin)
            delete(windowHandle.FigureHandle)
            evalin('caller', ['clear ' inputname(1)]);
        end
        % A method for displaying the object
        function disp(windowHandle)
            if numel(windowHandle) > 1
                fprintf(1, '%d-by-%d %s Object\n', size(windowHandle, 1), size(windowHandle, 2), class(windowHandle));
            else
                getdisp(windowHandle); fprintf(1, '\n');
                get(windowHandle.FigureHandle);
            end
        end
        % A method for get
        propVal = get(windowHandle, propName)
        % A method for set
        set(windowHandle, varargin)
    end
    
    
    
    %% Class-Specific Methods
    methods (Access = protected)
        % Add input property values to the object
        drawWindow(windowHandle, varargin)
    end
    
    
    
    %% Static Methods
    methods (Static, Access = protected)
        % Translate position & size strings
        outData = translate(inData, figPos)
    end
end



            