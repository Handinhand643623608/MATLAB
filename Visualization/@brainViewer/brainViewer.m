classdef brainViewer < Window
%BRAINVIEWER
%

%% CHANGELOG
%   Written by Josh Grooms on 20131208
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).
%       20160525:   Updated to restore minimum working functionality (still pretty buggy, though).

%% TODOS
% TODO - Implement speed improvements
% TODO - Implement recalculation of slice paging indices for patch data whenever the isovalue is changed
% TODO - Implement speed improvements for switching slice planes while functional data is displayed
% TODO - GUI improvements
% TODO - Make documentation for this object
% TODO - Improve or remove the Colin Brain renderings
% TODO - Improve functional-anatomical image registration



    %% Object Properties
    properties (SetObservable, AbortSet)
        AnatomicalBrain = 'MNIHD';
        IsoValue = 0.55;
        Menus
        MousePosition
        Parameters
        Patches
        SlicePlane = 'Transverse'
        SlicePosition
    end


    %% Constructor Method
    methods
        function brainData = brainViewer(varargin)
            %BRAINVIEWER Constructs a window object & display a 3D brain inside.
            % Initialize a window object for displaying the data
            brainData = brainData@Window(...
                'Background',   'k',...
                'MenuBar',      'figure',...
                'Position',     WindowPositions.UpperRight,...
                'Size',         WindowSizes.QuarterScreen); drawnow

            % Initialize modeling parameters
            initializeParameters(brainData, varargin{:});
            % Initialize the GUI
            initializeGUI(brainData);
            % Perform image corrections & coloration
            preprocess(brainData);
            % Determine slice positions in patch data (for rapid slice paging)
            calculateSlicePositions(brainData);
            % Render the brain in 3D
            renderBrain(brainData);
            % Fuse anatomical & data images
            fuseImages(brainData);
        end
    end


    %% Rendering Methods
    methods (Access = protected)
        % Change the data set for the anatomical brain rendering
        function changeBrain(brainData, src, ~)
            set(brainData.Menus.Settings.Render.(brainData.AnatomicalBrain), 'Checked', 'off');
            brainData.AnatomicalBrain = get(src, 'Label');
            set(brainData.Menus.Settings.Render.(brainData.AnatomicalBrain), 'Checked', 'on');
            delete(brainData.Patches.Surface, brainData.Patches.Cap);
            render(brainData, brainData.Data.Functional, brainData.Parameters.Threshold);
        end

        % Change the plane used to slice the brain volume while the figure is running
        function changeSlicePlane(brainData, src, ~)
            set(brainData.Menus.Settings.SlicePlane.(brainData.SlicePlane), 'Checked', 'off');
            brainData.SlicePlane = get(src, 'Label');
            set(brainData.Menus.Settings.SlicePlane.(brainData.SlicePlane), 'Checked', 'on');
            delete(brainData.Patches.Surface, brainData.Patches.Cap);
            render(brainData, brainData.Data.Functional, brainData.Parameters.Threshold);
        end

        % Generalized rendering process
        function render(brainData, varargin)
            initializeParameters(brainData, varargin{:});
            preprocess(brainData);
            calculateSlicePositions(brainData);
            renderBrain(brainData);
            fuseImages(brainData);
        end

        % Toggle anatomical direction text labels on or off
        function toggleDirectionLabels(brainData, varargin)
            labelNames = fieldnames(brainData.Text.Directions);
            for a = 1:length(labelNames)
                if strcmpi(get(brainData.Text.Directions.(labelNames{a}), 'Visible'), 'on')
                    set(brainData.Text.Directions.(labelNames{a}), 'Visible', 'off');
                    set(brainData.Menus.Settings.DirectionLabels, 'Checked', 'off')
                else
                    set(brainData.Text.Directions.(labelNames{a}), 'Visible', 'on');
                    set(brainData.Menus.Settings.DirectionLabels, 'Checked', 'on');
                end
            end
        end

    end


    %% Navigation Methods
    methods (Access = protected)
        % Make the mouse transparent & set up model rotation during a mouse click
        function clickFcn(brainData, varargin)
            brainData.MousePosition = get(brainData.FigureHandle, 'CurrentPoint');
            set(brainData.FigureHandle,...
                'Pointer', 'custom',...
                'PointerShapeCData', nan(16, 16),...
                'WindowButtonMotionFcn', @(src, evt) brainData.motionFcn(src, evt));
        end

        % Rotate the model with the mouse while holding a click
        function motionFcn(brainData, varargin)
            currentView = get(brainData.Axes, 'View');
            currentPosition = get(brainData.FigureHandle, 'CurrentPoint');
            diffView = brainData.MousePosition - currentPosition;
            set(brainData.Axes, 'View', currentView + diffView);
            brainData.MousePosition = currentPosition;
        end

        % Change the mouse cursor back to normal & stop rotating the model
        function releaseFcn(brainData, varargin)
            set(brainData.FigureHandle,...
                'Pointer', 'arrow',...
                'WindowButtonMotionFcn', '');
        end

        % Display slices of the brain using the mouse scroll wheel
        function sliceFcn(brainData, ~, evt)
            scrollNum = evt.VerticalScrollCount;
            brainData.SlicePosition = brainData.SlicePosition + scrollNum;
            sliceRange = brainData.Parameters.SliceRange;
            if brainData.SlicePosition > sliceRange(end); brainData.SlicePosition = sliceRange(end);
            elseif brainData.SlicePosition < sliceRange(1); brainData.SlicePosition = sliceRange(1); end
            set(brainData.Text.Slice.Number, 'String', num2str(brainData.SlicePosition));
            updateRender(brainData); drawnow
        end
    end


    %% Private Methods
    methods (Access = protected)
        % Set up important rendering parameters
        initializeParameters(brainData, varargin)
        % Initialize patch slice indices
        calculateSlicePositions(brainData)
        % Image corrections & coloration
        preprocess(brainData)
        % Render the 3-dimensional brain model
        renderBrain(brainData)
        % Update the brain model rendering
        updateRender(brainData)
    end

end
