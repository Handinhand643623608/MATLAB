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
%		20150128:	Finished implementing a static constructor method for creating EEG channel mapping montages.
%       20150129:   Updated the PLOT method to be a little more flexible with its inputs. It now optionally accepts a value
%                   for X or generates one using Y. Drafted some documentation for this method as well.
	
	

	%% DATA
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
		ElementAspect			% The [HEIGHT, WIDTH] aspect ratio of each montage element.
		ElementAxes				% An array of dimensions MONTAGESIZE containing axes handles for each montage element.
		ElementIndex			% The linear index of the montage element that will be plotted to next.
		ElementSize				% Size [HEIGHT, WIDTH] of each montage element in pixels.
		ExpandedFigures			% A list of figure handles that expanded element views that have been opened.
		MontageSize				% The [NROWS, NCOLS] size of the montage.
        Template				% A template of graphics objects that are shared across all montage elements.
		XTick                   % The array of tick positions for the primary x-axis.
        YTick                   % The array of tick positions for the primary y-axis.
	end



	%% PROPERTIES
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
	
	
	
	%% CONSTRUCTORS
	methods
		function H = Montage(m, varargin)
		% MONTAGE - Constructs a window object & initializes the plotting environment.
		
			% Initialize a window object for displaying the data
			H = H@Window(...
                'MenuBar', 'none',...
                'NumberTitle', 'off',...
                'Position', WindowPositions.CenterCenter,...
                'Size', WindowSizes.FullScreen); drawnow
			
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
                Colorbar = 'off';
                ColorbarLabel = [];
                Colormap = jet(256);
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
			
            if (istrue(Colorbar)); H.Colorbar = colorbar('EastOutside'); end
            
			H.SetElementSize();
			H.RetrofitPrimaryAxes();
			H.InitializeElementAxes();
			
			H.AxesColor = AxesColor;
			H.Box = Box;
			H.CLim = CLim;
			H.Color = Color;
            H.ColorbarLabel = ColorbarLabel;
            H.Colormap = Colormap;
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
	
	methods (Static)
        function H = EEG(x, varargin)
		% EEG - Creates a montage of colored EEG channel mappings.
		%
		%	SYNTAX:
		%		H = Montage.EEG(x)
		%		H = Montage.EEG(H, x)
		%		H = Montage.EEG(..., 'PropertyName', PropertyValue,...)
		%
		%	OUTPUT:
		%		H:					MONTAGE
		%							A reference to the montage object that was created or updated.
		%
		%	INPUTS:
		%		H:					MONTAGE
		%							A reference to a montage object that has already been set up to display EEG channel
		%							mappings. This input argument exists to allow the reuse of montages when imaging multiple
		%							data sets. Doing so prevents having to load and copy the channel mapping graphics
		%							template, which in turn greatly speeds up the display of data.
		%
		%		x:					[ 68 x M x N  DOUBLES ]
		%							An array of EEG data. This argument must always be formatted as dictated above with a
		%							single data point per channel stored along the rows of the array. The number of columns
		%							M dictates how many columns will be present in the montage, while the number of pages N
		%							dictates how many rows the montage will have. The size of this array must be constant
		%							across calls when reusing pre-existing montages (i.e. when inputting H in addition to x).
		%
		%	PROPERTIES:
		%		CLim:				DOUBLE or [ DOUBLE, DOUBLE ] or [ ]
		%							A one- or two-element vector that dictates the maximum and minimum values that the
		%							colormap will be scaled to. Inputting a single number here results in a CLim value that
		%							is symmetric about zero. Inputting an empty array for this argument results in a CLim
		%							value that is derived from the inputted data x.
		%							DEFAULT: []
		%
		%		Colorbar:			STRING
		%							A string that has a value of either 'on' or 'off' that in turn controls whether or not a
		%							colorbar is visible on the montage.
		%							DEFAULT: 'on'
		%
		%		Colormap:			[ NC x 3 DOUBLES ]
		%							The colormapping that will be used to represent the numeric data present in x. The number
		%							of discrete colors NC that are available for the mapping can be any positive integer.
		%							DEFAULT: jet(256)
		%
		%		ColorbarLabel:		STRING
		%							The string label that will be displayed to the right of the colorbar. This can be used to
		%							display the units that colors on the montage represent. This label will only be visible
		%							if the COLORBAR property is set to 'on'.
		%							DEFAULT: []
		%
		%		XLabel:				STRING
		%							The string label that will be displayed beneath the montage's primary x-axis and beneath
		%							the XTICKLABEL entries. This can be used to describe what the columns of the montage
		%							represent.
		%							DEFAULT: []
		%
		%		XTickLabel:			{ STRINGS } or [ DOUBLES ]
		%							The labels that will be displayed immediately beneath the x-axis. One label must be 
		%							present for each column displayed in the montage. This can be used to provide additional
		%							identifying information for the columns.
		%							DEFAULT: 1:M
		%
		%		YLabel:				STRING
		%							The string label that will be displayed to the left of the montage's primary y-axis and
		%							to the left of the XTICKLABEL entries. This can be used to describe what the rows of the
		%							montage represent.
		%							DEFAULT: []
		%
		%		YTickLabel:			{ STRINGS } or [ DOUBLES ]
		%							The labels that will be displayed immediately to the left of the y-axis. One label must
		%							be present for each row displayed in the montage. This can be used to provide additional
		%							identifying information for the rows.
		%							DEFAULT: 1:N
		%
		%	See also: BRAINPLOT, MONTAGE
		
			H = [];
            nchans = 68;
            assert(nargin >= 1, 'EEG data must be supplied to create a montage of channel mappings.');
			
			if isa(x, 'Montage')
				H = x;
				x = varargin{1};
				varargin(1) = [];
			end
			
			assert(isnumeric(x), 'EEG data must be provided as a numeric array with %d rows.', nchans);
			assert(size(x, 1) == nchans, 'EEG data must be correctly ordered and provided for all %d channels.', nchans);
			
			climBound = max(abs(x(:)));
			nx = size(x, 2);
			ny = size(x, 3);
			
			function Defaults
				CLim = [-climBound, climBound];
				Colorbar = 'on';
				Colormap = jet(256);
				ColorbarLabel = [];
				MajorFontSize = 20;
				MinorFontSize = 15;
				Title = [];
				XLabel = [];
				XTickLabel = 1:nx;
				YLabel = [];
				YTickLabel = 1:ny;
			end
			assignto(@Defaults, varargin);
			
			if isempty(H)
				H = Montage(ny, nx,...
					'CLim',				CLim,...
					'Colorbar',			Colorbar,...
					'Colormap',			Colormap,...
					'ColorbarLabel',	ColorbarLabel,...
					'MajorFontSize',	MajorFontSize,...
					'MinorFontSize',	MinorFontSize,...
					'Title',			Title,...
					'XLabel',			XLabel,...
					'XTickLabel',		XTickLabel,...
					'YLabel',			YLabel,...
					'YTickLabel',		YTickLabel);
			end
			
			H.Data = x;
			x = scale2rgb(x, 'Colormap', H.Colormap, 'CLim', H.CLim);
			x = permute(x, [1 3 2 4]);
            x = reshape(x, [], 3);
			
			if isempty(H.Template)
				set(H.ElementAxes, 'Color', 'k');
				templateFile = File.Which('EEG Channel Map Template.fig');
				H.Template = hgload(templateFile.ToString(), struct('Parent', H.ElementAxes(1)));
				H.Patch = gobjects(size(x, 1), 1);
				
				for a = 1:numel(H.ElementAxes)
					idx = (a - 1) * nchans + 1;
					H.Patch(idx:(idx + nchans - 1)) = copyobj(H.Template, H.ElementAxes(a));
				end
			end
            
			for a = 1:size(x, 1)
				set(H.Patch(a),...
					'FaceColor',    x(a, :),...
					'EdgeColor',    x(a, :));
			end
			
			drawnow;
        end
    end
    
    
	
	%% UTILITIES 
	methods (Access = protected)
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
            
            xtl = H.XTickLabel;
            ytl = H.YTickLabel;
            if (length(xtl) >= idxCol) && (~isempty(xtl{idxCol})); xt = xtl{idxCol};
            else xt = num2str(idxCol); end
            if (length(ytl) >= idxRow) && (~isempty(ytl{idxRow})); yt = ytl{idxRow};
            else yt = num2str(idxRow); end
				
			% Apply the title to the expanded view axes
			expTitle = sprintf('%s: %s\n%s: %s', xl, xt, yl, yt);
			title(AE, expTitle);
		end
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
                'Units',        'pixels',...
                'Color',        'none',...
                'Parent',       H.FigureHandle,...
                'TickLength',   [0 0],...
                'XLim',         [0 1],...
                'XTick',        [],...
                'YLim',         [0 1],...
                'YTick',        []);
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
		function RetrofitPrimaryAxes(H)
        % RETROFITPRIMARYAXES - Fits the primary axes to the montage once element sizing is finalized.
            fpos = getpixelposition(H.FigureHandle);
            apos = [0, 0, H.ElementSize .* [H.MontageSize(2) H.MontageSize(1)]];
            apos(1) = (fpos(1) + fpos(3) - apos(3)) / 2;
            apos(2) = (fpos(2) + fpos(4) - apos(4)) / 2;
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
                'Units',                    'pixels',...
				'ButtonDownFcn',            @H.ExpandElement,...
                'CLim',                     H.CLim,...
                'CLimMode',                 'manual',...
                'Color',                    'none',...
                'Parent',                   H.FigureHandle,...
                'Position',                 position,...
                'TickLength',               [0, 0],...
				'XColor',                   'k',...
				'XLimMode',                 'manual',...
                'XTick',                    [],...
				'XTickLabelMode',           'manual',...
				'YColor',                   'k',...
				'YLimMode',                 'manual',...
                'YTick',                    [],...
				'YTickLabelMode',           'manual');
		end
	end
	
	methods		
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
		
        function Close(H, varargin)
		% CLOSE - Closes the montage window and any expanded element windows that remain open.
			if (H.ExpandedFigures ~= 0); delete(H.ExpandedFigures); end
			Close@Window(H);
		end
		function Plot(H, x, y, varargin)
		% PLOT - Creates a 2D plot in the next available montage element.
        %
        %   PLOT operates similarly to the native MATLAB PLOT method in that it generates a two-dimensionsal plot of Y versus
        %   X as a solid line. However, at present it is somewhat less flexible than its native counterpart and does not
        %   support the changing of many of its settings. It is intended for use as a quick and easy way to produce several
        %   grouped function or signal plots in a montage. If more advanced functionality than this is required, the montage
        %   axes must be plotted to outside of this class using the AXES handle returned by the method NEXTELEMENT.
        %
        %   PLOT automatically manages the filling of a montage by advancing the axes counter every time it is called.
        %   Consequently, this method may be called repeatedly until all montage elements are filled.
        %
        %   SYNTAX:
        %       H.Plot(y)
        %       H.Plot(x, y)
        %       H.Plot(..., 'PropertyName', PropertyValue,...)
        %       Plot(H,...)
        %
        %   INPUT:
        %       H:              MONTAGE
        %
        %       x:              [ DOUBLES ]
        %
        %       y:              [ DOUBLES ]
        %
        %   PROPERTIES:
        %       LineColor:      [ R, G, B ]
        %
        %       LineWidth:      DOUBLE
		
            assert(nargin >= 2, 'Data must be provided in order to generate a plot.');
            assert(isnumeric(x), 'Only numeric data can be plotted in a montage element.');
            if (nargin == 2) || isempty(y)
                y = x; 
                x = [];
            elseif ischar(y)
                varargin = [y varargin];
                y = x;
                x = [];
            end
                
			function Defaults
				LineColor = [0, 0.5, 0.75];
				LineWidth = 1.25;
			end
			assignto(@Defaults, varargin);
		
            if isempty(x)
                if isvector(y); x = 1:length(y);
                else x = 1:size(y, 1); end
            end
            
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

% 			error('This method has not yet been implemented.');
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

	
	
end