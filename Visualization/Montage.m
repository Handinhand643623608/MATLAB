classdef Montage < Window
% MONTAGE - Displays a tightly packed grouping of MATLAB axes objects used for plotting.
%
%

%% CHANGELOG
%	Written by Josh Grooms on 20141208
%		20141212:	Changed how the y-axis tick labels are displayed by default. They are now flipped automatically by
%					the getter/setter methods of this class so that first element of the inputted array is displayed at
%					the top and subsequent tick labels are displayed under it (i.e. towards the origin). This was done
%					because this is how the montage is created, meant to be read, and because I keep making the mistake
%					of not flipping the labels myself in code that uses the montage.
%		20141215:	Fixed some bugs in the titling of expanded element views.
	
	

	%% Montage Properties
	properties (Dependent)
        AxesColor               % The color of the primary plot axes.
		Box
        CLim                    % The [MIN, MAX] data values that are mapped to colormap extremes.
        ColorbarLabel           % A label string for the plot's colorbar.
        Title                   % The title string of the plot.
        XLabel                  % The x-axis label string.
		XLim					% The [MIN, MAX] values displayed on an element's x-axis.
        XTickLabel              % The individual x-axis tick labels.
        YLabel                  % The y-axis label string.
		YLim					% The [MIN, MAX] values displayed on an element's y-axis.
        YTickLabel              % The individual y-axis tick labels.
	end	

	properties (AbortSet)
		MajorFontSize           % The font size (in font units) of major plot text (e.g. titles, axis titles, etc.).
        MinorFontSize           % The font size (in font units) of minor plot text (e.g. axis tick labels).
	end
	
	properties (Access = protected, Hidden)
		ElementAspect
		ElementAxes
		ElementIndex
		ElementSize
		ExpandedFigures
		MontageSize
		XTick                   % The array of tick positions for the primary x-axis.
        YTick                   % The array of tick positions for the primary y-axis.
	end



	%% Constructor Method
	methods
		function H = Montage(m, varargin)
		% MONTAGE - Constructs a window object & initializes the plotting environment.
		
			% Initialize a window object for displaying the data
			H = H@Window(...
                'MenuBar', 'none',...
                'NumberTitle', 'off',...
                'Position', WindowPositions.CenterCenter,...
                'Size', WindowSizes.FullScreen); drawnow
% 			set(H.FigureHandle, 'CloseRequestFcn', @H.Close);
			
			% Error check
			assert(nargin >= 1, 'Constructing a montage requires a size to be specified.');
			
			% Determine the size of the axes array that will form the montage
			if isnumeric(varargin{1})
				n = varargin{1};
				varargin(1) = [];
			else
				n = m;
			end
			
			% Overridable default settings
			function Defaults	
				AxesColor = 'k';
				Box = 'on';
				CLim = [];
				Color = 'w';
				ElementAspect = [1, 1];
				MajorFontSize = 25;
				MinorFontSize = 20;
				Title = [];
				XLabel = [];
				XLim = [0, 1];
				XTickLabel = [];
				YLabel = [];
				YLim = [0, 1];
				YTickLabel = [];
			end
			assignto(@Defaults, varargin);
			
			H.ElementIndex = 1;
			H.MontageSize = [m, n];
			
			H.ElementAspect = ElementAspect;
			H.InitializePrimaryAxes();
			H.SetAxesTickSpacing();
			
			H.SetElementSize();
			H.RetrofitPrimaryAxes();
			H.InitializeElementAxes();
			
			H.AxesColor = AxesColor;
			H.Box = Box;
			H.CLim = CLim;
			H.Color = Color;
			H.ExpandedFigures = gobjects(1);
			H.MajorFontSize = MajorFontSize;
			H.MinorFontSize = MinorFontSize;
			H.Title = Title;
			H.XLabel = XLabel;
			H.XLim = XLim;
			H.XTickLabel = XTickLabel;
			H.YLabel = YLabel;
			H.YLim = YLim;
			H.YTickLabel = YTickLabel;
			
		end
	end
	
	
	
	%% Public Utility Methods
	methods
        
		function Close(H, varargin)
		% CLOSE - Closes the montage window and any expanded element windows that remain open.
			delete(H.ExpandedFigures);
			Close@Window(H);
		end
		
		function A = NextElement(H)
		% NEXTELEMENT - Returns a handle to the next montage element axes to be plotted to.
		%
		%	NEXTELEMENT provides an easy means of serially filling in a montage using custom-written plotting commands.
		%	When this method is called, it returns a handle to the next empty axes object in the montage and advances an
		%	internal counter that tracks which montage elements have been used. This returned axes handle can then be
		%	used with other graphics functions to generate complicated plots that the methods of the MONTAGE class are
		%	incapable of producing.
		%
		%	The ordering of handles that NEXTELEMENT returns follows the same column-major ordering that MATLAB uses for
		%	linear array indexing. In other words, the first invocation of this method returns a handle corresponding
		%	with the upper-left-most axes while a subsequent invocation returns a handle to the axes immediately below
		%	it. This will continue until all handles in the montage have been used, at which point any further calls to
		%	NEXTELEMENT will generate errors.
		%
		%	For convenience, this method is called automatically by the plotting methods that the MONTAGE class
		%	provides.
		%
		%	SYNTAX:
		%		A = H.NextElement()
		%		A = NextElement(H)
		%
		%	OUTPUT:
		%		A:		AXES
		%				A handle to the next MATLAB axes object that is available for plotting.
		%
		%	INPUT:
		%		H:		MONTAGE
		%				A single montage object.
			assert(H.ElementIndex <= numel(H.ElementAxes), 'Attempted to access axes outside of montage dimensions.');
			A = H.ElementAxes(H.ElementIndex);
			H.ElementIndex = H.ElementIndex + 1;
		end
		
		function Plot(H, x, y, varargin)
		% PLOT - Creates a 2D plot in the next available montage element.
		
			function Defaults
				LineColor = [0, 0.5, 0.75];
				LineWidth = 1.25;
			end
			assignto(@Defaults, varargin);
		
			% A line is used here because "plot" resets a bunch of axes properties to "auto"
			A = H.NextElement();
			cla(A);
			line(x, y,...
				'Color', LineColor,...
				'LineWidth', LineWidth,...
				'Parent', A);
		end
		function Recycle(H, title)
		% RECYCLE - Recycles an existing montage object by replacing the plotted data with a new data set.
		%
		%	SYNTAX:
		%		H.Recycle(data)
		%		H.Recycle(data, title)
		%		Recycle(H,...)
		%
		%	INPUTS:
		%		H:			BRAINPLOT
		%					A reference to a single pre-existing BRAINPLOT montage object.
		%
		%		data:		[ NUMERICS ]
		%					A new array of numeric data to be plotted. This array must be the same size as the data
		%					array that was used to construct the original montage (i.e. through the constructor method).
		%					In other words, SIZE(data) must be equal to SIZE(H.DATA).
		%
		%	OPTIONAL INPUT:
		%		title:		STRING
		%					A new title string to be displayed above the montage that will replace any existing title.
		%					If this argument is omitted, the title from the previous montage will remain unchanged.
		%					DEFAULT: H.Title
			if (nargin == 1); title = H.Title; end
			H.Title = title;
			H.ElementIndex = 1;
		end
		function Refresh(H)
		% REFRESH - Redraws the plots in each individual montage element using stored data.
		%
		%	This function refreshes the plots across the entire montage, overwritting any existing plots with updated
		%	renderings. REFRESH is useful when changing properties of the figure axes that are required by the
		%	individual plots themselves in order to be displayed properly (e.g. the CLim property). In such cases, the
		%	existing plots must be completely redrawn in order to incorporate those changes. REFRESH uses the montage
		%	object's stored data array to redraw the images.
		%
		%	SYNTAX:
		%		H.Refresh()
		%		Refresh(H)
		%
		%	INPUT:
		%		H:		BRAINPLOT
		%				A reference to a single BrainPlot montage object.
% 			H.Plot();
		end
		function ShadedPlot(H, x, y, z, varargin)
		% SHADEDPLOT - Creates a 2D plot with a shaded region in the next available montage element.
		%
		%	SHADEDPLOT operates exactly like the function PLOT in that it generates a two-dimensional plot of Y versus X
		%	as a solid line. However, unlike PLOT this method takes an additional variable Z that is used to generate a
		%	shaded region within the same axes. This is useful for creating plots of averages and their standard
		%	deviations or standard errors. Use of shading also tends to look prettier than comparable functions like
		%	ERRORBAR.
		%
		%	SHADEDPLOT automatically manages the filling of a montage and advancing of the axes counter through
		%	NEXTELEMENT. Thus, this method may be called repeatedly until all montage elements are filled.
		%
		%	SYNTAX:
		%		H.ShadedPlot(x, y, z)
		%		H.ShadedPlot(x, y, z, 'PropertyName', PropertyValue,...)
		%		ShadedPlot(H,...)
		%
		%	INPUTS:
		%		H:				MONTAGE
		%						A single montage window object containing a pre-initialized array of axes that will be
		%						used to display the shaded plot.
		%
		%		x:				[ NUMERICS ]
		%						A single vector of numeric data representing the X coordinates of points that will form
		%						the plot. This vector may be of any length and orientation but must match the lengths of
		%						Y and Z exactly. Arrays of data are not supported for this argument.
		%
		%		y:				[ NUMERICS ]
		%						A single vector of numeric data representing the Y coordinates of points that will form
		%						the plot. Elements of this vector should correspond with elements in X at the same
		%						indices. This vector may be of any length and orientation but must match the lengths of
		%						X and Z exactly. Arrays of data are not supported for this argument.
		%
		%		z:				[ NUMERICS ]
		%						A vector or array of numeric data that will be used to form the shaded region on the
		%						plot. Elements of this array should correspond with elements in X and Y at the same
		%						indices. This array may be of any length (where LENGTH = MAX(SIZE(Z))) and orientation
		%						but must match the lengths of X and Y exactly.
		%
		%						If Z is inputted as a vector, a shaded region will be drawn around the curve of Y versus
		%						X that is bounded by Y +/- Z. The upper and lower bounds of the shaded region can also
		%						be drawn independently of one another by inputting an array for Z. In this case, the
		%						first row or column (depending on orientation) will bound the region above Y (i.e. Y +
		%						Z(:, 1) or Y + Z(1, :)) while the second provides the lower bound.
		%
		%	OPTIONAL INPUTS:
		%		'Alpha':		DOUBLE
		%						The amount of transparency that should be used for the shaded region. This number can
		%						vary between 0 (completely transparent) and 1 (completely opaque).
		%						DEFAULT: 0.3
		%
		%		'LineColor':	[ R, G, B ]
		%						The color of the solid line (from the Y argument) that will be plotted.
		%						DEFAULT: [0, 0.5, 0.75]
		%
		%		'LineWidth':	DOUBLE
		%						The thickness of the solid line (from the Y argument) that will be plotted.
		%						DEFAULT: 1.25
		%
		%		'ShadeColor':	[ R, G, B ]
		%						The color of the shaded region.
		%						DEFAULT: [0, 0.5, 0.75]
		%
		%	See also: PLOT, MONTAGE.NEXTELEMENT
			
			% Error checks
			assert(isvector(x) && isvector(y) && isnumeric(x) && isnumeric(y),...
				'Data being plotted must be vectors of a numeric type.');
			assert(ismatrix(z) && isnumeric(z) && any(size(z) <= 2),...
				'Shading data must be provided as a vector or a matrix with either two rows or columns.');
			assert(isequal(length(x), length(y), length(z)),...
				'Data being plotted must all be of equal length.');
			
			% Overridable default settings
			function Defaults
				Alpha = 0.3;
				LineColor = [0, 0.5, 0.75];
				LineWidth = 1.25;
				ShadeColor = [0, 0.5, 0.75];
			end
			assignto(@Defaults, varargin);
			
			% Format the inputted data
			x = x(:);
			y = y(:);
			if isvector(z)
				z = repmat(z(:), 1, 2);
			elseif (~all(size(z) == 2) && size(z, 1) == 2)
				z = z';
			end
			
			% Format the axes object being plotted to
			A = H.NextElement();
			set(A, 'NextPlot', 'add');
			
			% Plot the data
			fill(...
				[x; flip(x)],...
				[y+z(:, 1); flip(y-z(:, 2))],...
				ShadeColor,...
				'EdgeColor', 'none',...
				'FaceAlpha', Alpha,...
				'Parent', A);
			plot(A, x, y, 'Color', LineColor, 'LineWidth', LineWidth);
			
		end
		
	end
	
	
	
	%% Get & Set Methods
    methods
        
        % Get methods
        function color  = get.AxesColor(H)
            color = get(H.Axes, 'XColor');
		end
		function box	= get.Box(H)
			box = get(H.ElementAxes(1), 'Box');
		end
        function clim   = get.CLim(H)
            clim = get(H.Axes, 'CLim');
        end
        function clabel = get.ColorbarLabel(H)
            clabel = get(get(H.Colorbar, 'YLabel'), 'String');
        end
        function title  = get.Title(H)
            title = get(get(H.Axes, 'Title'), 'String');
        end
        function xlabel = get.XLabel(H)
            xlabel = get(get(H.Axes, 'XLabel'), 'String');
		end
		function xlim	= get.XLim(H)
			xlim = get(H.ElementAxes(1), 'XLim');
		end
        function xtick  = get.XTickLabel(H)
            xtick = get(H.Axes, 'XTickLabel');
			if ischar(xtick); xtick = cellstr(xtick); end
        end
        function ylabel = get.YLabel(H)
            ylabel = get(get(H.Axes, 'YLabel'), 'String');
		end
		function ylim	= get.YLim(H)
			ylim = get(H.ElementAxes(1), 'YLim');
		end
        function ytick  = get.YTickLabel(H)
            ytick = get(H.Axes, 'YTickLabel');
			if ischar(ytick); ytick = cellstr(ytick); end
			ytick = flip(ytick);
        end
        
        % Set methods
        function set.AxesColor(H, color)
            set(H.Axes, 'XColor', color, 'YColor', color);
            set(get(H.Axes, 'Title'), 'Color', color);
            set(get(H.Axes, 'XLabel'), 'Color', color);
            set(get(H.Axes, 'YLabel'), 'Color', color);
            set(get(H.Colorbar, 'YLabel'), 'Color', color);
		end
		function set.Box(H, box)
			if istrue(box); box = 'on';
			else box = 'off'; end
			set(H.ElementAxes, 'Box', box);
		end
        function set.CLim(H, clim)
			if (nargin == 1 || isempty(clim))
				if isempty(H.Data)
					set(H.Axes, 'CLimMode', 'auto');
					return;
				else
					climBound = max(abs(H.Data(:)));
					clim = [-climBound, climBound];
				end
			elseif (length(clim) == 1)
				clim = [-clim, clim];
			end
            set(H.Axes, 'CLim', clim);
			H.Refresh();
        end
        function set.ColorbarLabel(H, clabel)
            set(get(H.Colorbar, 'YLabel'), 'String', clabel);
        end
        function set.MajorFontSize(H, fsize)
            set(get(H.Colorbar, 'YLabel'), 'FontSize', fsize);
            set(get(H.Axes, 'Title'), 'FontSize', fsize);
            set(get(H.Axes, 'XLabel'), 'FontSize', fsize);
            set(get(H.Axes, 'YLabel'), 'FontSize', fsize);
            H.MajorFontSize = fsize;
        end
        function set.MinorFontSize(H, fsize)
            set(H.Colorbar, 'FontSize', fsize);
            set(H.Axes, 'FontSize', fsize);
            H.MinorFontSize = fsize;
        end
        function set.Title(H, title)
            set(get(H.Axes, 'Title'), 'String', title);
        end
        function set.XLabel(H, xlabel)
            set(get(H.Axes, 'XLabel'), 'String', xlabel);
		end
		function set.XLim(H, xlim)
			set(H.ElementAxes, 'XLim', xlim);
		end
        function set.XTickLabel(H, tlabels)
            set(H.Axes, 'XTick', H.XTick, 'XTickLabel', tlabels);
        end
        function set.YLabel(H, ylabel)
            set(get(H.Axes, 'YLabel'), 'String', ylabel);
		end
		function set.YLim(H, ylim)
			set(H.ElementAxes, 'YLim', ylim);
		end
        function set.YTickLabel(H, tlabels)
            set(H.Axes, 'YTick', H.YTick, 'YTickLabel', flip(tlabels));
		end
		
    end
	
	
	
	
	%% Protected Class Utility Methods
	methods (Access = protected)
		
		function InitializeElementAxes(H)
        % INITIALIZEELEMENTAXES - Create an array of axes to serve as the individual montage elements.
            apos = get(H.Axes, 'Position');
            epos = [0, 0, H.ElementSize];
			H.ElementAxes = gobjects(H.MontageSize(1), H.MontageSize(2));
            for a = 1:H.MontageSize(1)
                for b = 1:H.MontageSize(2)
                    epos(1) = (b - 1) * H.ElementSize(1) + apos(1);
                    epos(2) = (a - 1) * H.ElementSize(2) + apos(2);
                    H.ElementAxes(a, b) = H.NewElement(epos);
                end
            end
            H.ElementAxes = flip(H.ElementAxes, 1);    % Flipped so ordering starts from the upper left corner
        end
		function InitializePrimaryAxes(H)
		% INITIALIZEPRIMARYAXES - Creates axes that contain and label the image montage.
			H.Axes = axes(...
                'Color', 'none',...
                'Parent', H.FigureHandle,...
                'TickLength', [0 0],...
                'XLim', [0 1],...
                'XTick', [],...
                'YLim', [0 1],...
                'YTick', []);
		end
		function RetrofitPrimaryAxes(H)
        % RETROFITPRIMARYAXES - Fits the primary axes to the montage once element sizing is finalized.
            apos = [0, 0, H.ElementSize .* [H.MontageSize(2) H.MontageSize(1)]];
            apos(1) = (1 - apos(3)) / 2;
            apos(2) = (1 - apos(4)) / 2;
            set(H.Axes, 'Position', apos);
        end
		function SetElementSize(H)
        % SETELEMENTSIZE - Calculates the size of montage elements.
            apos = get(H.Axes, 'Position');
            asize = apos(3:4);
            width = asize(1)/H.MontageSize(2);
            height = width * (H.ElementAspect(2) / H.ElementAspect(1));
            if (height * H.MontageSize(1) > asize(2))
                height = asize(2) / H.MontageSize(1);
                width = height * (H.ElementAspect(1) / H.ElementAspect(2));
            end
            H.ElementSize = [width, height];
		end
		function SetAxesTickSpacing(H)
        % SETAXESTICKSPACKING - Determines the spacing between X- & Y-axis ticks.
            xSpacing = 1/H.MontageSize(2);
            ySpacing = 1/H.MontageSize(1);
            xHalfSpacing = 0.5*xSpacing;
            yHalfSpacing = 0.5*ySpacing;
            H.XTick = linspace(xHalfSpacing, 1 - xHalfSpacing, H.MontageSize(2));
            H.YTick = linspace(yHalfSpacing, 1 - yHalfSpacing, H.MontageSize(1));
		end
		
		function A = NewElement(H, position)
        % NEWELEMENT - Creates individual montage element axes at the specified position.
        %
        %   SYNTAX:
        %       A = NewElement(H, position)
        %       A = H.NewElement(position)
        %
        %   OUTPUT:
        %       A:          HANDLE
        %                   A handle to the axes graphics object that is generated by this method.
        %
        %   INPUTS:
        %       H:          BRAINPLOT
        %                   A single BrainPlot object to which a new element should be added.
        %
        %       position:   [ DOUBLE, DOUBLE, DOUBLE, DOUBLE ] --> [ X, Y, WIDTH, HEIGHT ]
        %                   A four-element position-size vector indicating where the new montage element should be
        %                   placed in the figure and how big it should be. Position is specified using the first two
        %                   elements of this vector and is relative to the boundaries of the primary axes. Size is
        %                   specified through the last two elements of this vector.
            A = axes(...
				'ButtonDownFcn', @H.ExpandElement,...
                'CLim', H.CLim,...
                'CLimMode', 'manual',...
                'Color', 'none',...
                'Parent', H.FigureHandle,...
                'Position', position,...
				'XColor', 'k',...
				'XLimMode', 'manual',...
                'XTick', [],...
				'XTickLabelMode', 'manual',...
				'YColor', 'k',...
				'YLimMode', 'manual',...
                'YTick', [],...
				'YTickLabelMode', 'manual');
		end
		
		function ExpandElement(H, src, ~)
		% EXPANDELEMENT - Copies the contents of a clicked montage element into a larger new figure window.
		%
		%	EXPANDELEMENT is a callback function tied to the BUTTONDOWNFCN property of all axes objects present in the
		%	montage. It is automatically called when a left mouse click is detected over one of these axes. This method
		%	then determines which particular axes detected the click and opens a new window that displays a larger
		%	version of the montage element, which is useful for closer inspections of data that would otherwise be
		%	difficult to see in montage form.
			
			% Generate a new figure & axes for the expanded view
			H.ExpandedFigures = cat(1, H.ExpandedFigures, figure('CloseRequestFcn', @H.OnExpansionClosing));
			AE = axes(...
				'CLim', H.CLim,...
				'CLimMode', 'manual',...
				'Color', 'none',...
				'Parent', H.ExpandedFigures(end),...
				'XLim', H.XLim,...
				'YLim', H.YLim);
			
			% Copy the data plotted in the montage into the expanded view
			[idxRow, idxCol] = find(H.ElementAxes == src);
			A = H.ElementAxes(idxRow, idxCol);
			copyobj(get(A, 'Children'), AE);

			% Generate a generic title to identify the displayed data
			if isempty(H.XLabel); xl = 'X';
			else xl = H.XLabel; end
			if isempty(H.YLabel); yl = 'Y';
			else yl = H.YLabel; end
			if isempty(H.XTickLabel{idxCol}); xt = num2str(idxCol);
			else xt = H.XTickLabel{idxRow}; end
			if isempty(H.YTickLabel); yt = num2str(idxRow);
			else yt = H.YTickLabel{idxRow}; end
				
			% Apply the title to the expanded view axes
			expTitle = sprintf('%s: %s\n%s: %s', xl, xt, yl, yt);
			title(AE, expTitle);
		end
		function OnExpansionClosing(H, src, ~)
		% ONEXPANSIONCLOSING - Deletes expanded element windows and removes their handles from further tracking.
		%
		%	ONEXPANSIONCLOSING is a callback function tied to the CLOSEREQUESTFCN property of MATLAB figures. It is
		%	called automatically when CLOSE (but not DELETE) is called on any open element expansion figures. This
		%	method intercepts the native closing routing in order to first remove the figure handle from the list of
		%	tracked secondary windows that a montage object maintains.
			idxFE = H.ExpandedFigures == src;
			delete(H.ExpandedFigures(idxFE));
			H.ExpandedFigures(idxFE) = [];
		end
		
	end

	
	
end