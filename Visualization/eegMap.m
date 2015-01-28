% EEGMAP - Plots a spatial mapping of EEG electrodes and fills electrodes with color.
%
%   SYNTAX:
%   eegmap()
%   eegmap(X)
%   eegmap(X, 'PropertyName', PropertyValue,...)
%   H = eegmap(...)
%   
%   OPTIONAL OUTPUT:
%   H:              WINDOW or HANDLE
%                   A handle to the window or figure object containing the plotted EEG map. If the PARENT argument is not
%                   used, then this will point to an object of the WINDOW class, which also contains handles to the various
%                   elements seen on the map. Otherwise, this will point to whichever object contains the inputted axes
%                   handle.
%   
%   OPTIONAL INPUTS:
%   X:              [ 68 x 1 DOUBLES ] or [ 68 x 3 DOUBLES ] or STRING or { STRINGS }
%                   This input argument is used to control the coloring of electrodes. As such, a diverse range of formats
%                   are supported for it. If no inputs are provided for this function, all channels are drawn and filled in
%                   uniformly.
%
%                   If numeric data are provided for X, they must be formatted as an array with 68 rows, where each row
%                   corresponds with a particular EEG channel. The channels must also be ordered correctly (using the typical
%                   ordering scheme found throughout my data - see 'eegInfo.mat' for a list). If a vector is inputted for X,
%                   the numeric data will be automatically scaled to span the entire figure color mapping. This is useful for
%                   displaying an EEG data vector containing correlation coefficients or some other metric. Alternatively,
%                   colors can be controlled directly by providing RGB values for each electrode (i.e. a 68 x 3 array).
%
%                   This function also supports a 'demonstration' mode that highlights any electrodes specified in X. To use
%                   this mode, input a string or cell array of strings containing the name(s) of the electrode(s) that should
%                   be highlighted. Electrode name strings are not case sensitive here. All electrodes will still be drawn,
%                   but only those corresponding to the input X will be highlighted a different color (controlled by the
%                   FILLCOLOR argument).
%
%   'FillColor':    [ 1 x 3 RGB ] OR STRING
%                   An RGB color vector or a MATLAB predefined color name string that specifies the color of filled
%                   electrodes on the map. This is only used when specific electrodes are inputted to be highlighted. If
%                   numeric data are inputted to determine color values, this property has no effect.
%                   DEFAULT: [0 0.25 1] (a lighter blue)
%
%   'Parent':       HANDLE
%                   A MATLAB graphics handle pointing to an axes object. This argument is used to control where the EEG
%                   electrode mapping is displayed and is helpful when making montages or GUIs that require EEG data
%                   visualization. By default, this function creates its own window and axes objects to display mappings.
%                   DEFAULT: []
%
%   'ShowLabels':   BOOLEAN
%                   A Boolean true/false that specifies whether or not electrode text labels are displayed on the map. If
%                   enabled, labels are centered on top of the colored electrode circle. Otherwise, only a colored circle is
%                   displayed.
%                   DEFAULT: true
%
%   'Size':         WINDOWSIZES
%                   One of the window size enumerators specifying how large the plot window should be. This is a setting
%                   carried directly over from the WINDOW class, and all options supported there are available. This setting
%                   is only used when a window is created from within this function to display the plot. If the PARENT
%                   argument above is used, this parameter has no effect.
%                   DEFAULT: WindowSizes.FullScreen

%% CHANGELOG
%   Written by Josh Grooms on 20130902
%       20140109:   Major overhaul of function initialization to support a kind of "demo" mode where the user can
%                   manually select electrodes to be highlighted on the plot. Implemented custom color selection of
%                   highlighted electrodes (not available for data input). Hard coded some default color options that
%                   were infrequently changed before (edge, text, background colors). Implemented plotting to window
%                   objects instead of figures. Implemented the optional output of the window object handle. Completely
%                   re-wrote function documentation.
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).
%       20140904:   Bug fixes for compatibility with new COLOR class (required renaming a variable) and for deleting the
%                   list of EEG channels that this function used to reference (these data are now a part of the
%                   BRAINPLOT class).
%       20140923:   Bug fix for deleting the structure of EEG electrode scalp coordinates that this function used to
%                   reference (these data are now a part of the BRAINPLOT class).
%       20150127:   Completed a major overhaul of this function after it stopped working (version R2014b breaks it). Also
%                   overhauled the documentation for this function.



%% FUNCTION DEFINITION
function varargout = eegmap(x, varargin)

	% Initialize default values & settings
	function Defaults
		FillColor = [0, 0.25, 1];
		Parent = [];
		ShowLabels = true;
		Size = WindowSizes.FullScreen;
	end
	assignto(@Defaults, varargin);
	
	% Load data stored elsewhere
	infoFile = File.Which('eegInfo.mat');
	template = File.Which('eegPlot.fig');
	[channels, coordinates] = infoFile.Load();

	% Do some input argument formatting & error checking
	if (nargin == 0);		x = channels;
	elseif (ischar(x));		x = { x };
	else
		assert(ismatrix(x) && length(x) == length(channels),...
			'Unrecognized value found for the input argument x. See documentation for correct function usage and syntax.');
		if size(x, 2) == length(channels); x = x'; end
		if size(x, 2) ~= 3; x = scale2rgb(x); end
	end
	
	if ischar(FillColor);	FillColor = str2rgb(FillColor);
	else
		assert(isvector(FillColor) && length(FillColor) == 3,...
			'The FillColor parameter must be a valid 3-element RGB vector or color string.');
	end
	
	if isempty(Parent)
		H = GenerateFigure(Size);
		Parent = H.Axes;
	else
		assert(ishandle(Parent), 'The parent graphics object must be a single pre-existing axes object.');
	end
		
	% If running in demo mode (just seleting channels to be labeled), color the input channels
	if iscellstr(x)
		coloredChannels = zeros(length(channels), 3);
        idsToColor = ismember(lower(channels), lower(x));
		coloredChannels(idsToColor, :) = repmat(FillColor, sum(idsToColor), 1);
		x = coloredChannels;
	end
	
	% Create the electrode mapping or load an existing one (much faster, if one exists) & color it in
	if (template.Exists);	circles = LoadMapping(Parent, template);
	else					circles = GenerateMapping(coordinates, channels); end
	Fill(circles, x, ShowLabels);
	
	% Fill in output object data
	if isa(H, 'Window')
		windowHandle.Text = circles(:, 1);
		windowHandle.Data.Patch = circles(:, 2);
		windowHandle.Data.Color = x;
	end
	assignOutputs(nargout, windowHandle);
	
end



%% SUBROUTINES
function Fill(C, x, showLabels)
% FILL - Fills electrode circle patches with color.
%
%   INPUTS:
%       C:              [ 68 x 2 HANDLES ]
%                       The first column is circle patch handles while the second column is text object handles.
%
%       x:              [ 68 x 3 RGB ]
%                       One row of RGB data per electrode.
%
%       showLabels:     BOOLEAN
%                       Controls whether electrode name labels are shown.
	if istrue(showLabels);	showLabels = 'on';
	else showLabels = 'off'; end
	
	for a = 1:size(x, 1)
		set(C(a, 2),...
			'FaceColor', x(a, :),...
			'EdgeColor', 'w');
		set(C(a, 1),...
			'Color', 'w',...
			'FontUnits', 'points',...
			'FontSize', 12,...
			'FontWeight', 'normal',...
			'Visible', showLabels);
	end
end
function H = GenerateFigure(size)
% GENERATEFIGURE - Generates a window and axes object to hold the EEG channel mapping.
%
%   OUTPUT:
%       H:      WINDOW
%               A reference to the window object that was created. The new axes are stored within it.
%
%   INPUT:
%       size:   WINDOWSIZES
%               One of the window size enumerators.
	H = Window('Size', size, 'Color', 'w');
	A = axes(...
		'Box', 'off',...
		'Color', 'none',...
        'XColor', 'w',...
		'XLim', [0, 1],...
		'XTick', [],...
        'YColor', 'w',...
		'YLim', [0, 1],...
		'YTick', []);
	H.Axes = A;
	axis square;
end
function C = GenerateMapping(A, coordinates, channels)
% GENERATEMAPPING - Generates electrode circle patches and associated text labels.
%
%   OUTPUT:
%       C:              [ 68 x 2 HANDLES ]
%                       The electrode patch handle array. The first column is circle patch handles. The second column is text
%                       object handles for electrode name labels.
%
%   INPUT:
%       A:              HANDLE
%                       A reference to an existing AXES object.
%   
%       coordinates:    STRUCT
%                       A structure with electrode names as field names and spatial coordinates as their values.
%   
%       channels:       { STRINGS }
%                       The electrode channel names.
    C = zeros(length(channels), 2);
	szLabels = zeros(length(channels), 4);
	coords = zeros(length(channels), 2);

	for a = 1:length(channels)
		coords(a, :) = coordinates.(channels{a});

		% Draw the text that will serve as the electrode labels
		C(a, 1) = text(coords(a, 1), coords(a, 2), channels{a}, 'Parent', A);
		set(C(a, 1),...
			'HorizontalAlignment', 'center',...
			'VerticalAlignment', 'middle',...
			'FontUnits', 'normalized',...
			'FontWeight', 'bold');

		% Get the size of the labels to determine how to scale the circle
		szLabels(a, :) = get(C(a, 1), 'Extent');
	end

	% Get the maximum width of all text (in order to make surrounding circles consistent)
	maxWidth = max(szLabels(:, 3));

	% Generate patch vertices for the circles
	t = 0:(2*pi/(99)):2*pi;
	cx = maxWidth.*sin(t);
	cy = maxWidth.*cos(t);

	for a = 1:length(channels)
		% Adjust the spatial position
		ctx = cx + coords(a, 1);
		cty = cy + coords(a, 2);

		% Create the circle object
		C(a, 2) = patch(ctx, cty, 'k');

		% Delete & refresh the text data (so it's on top of the circle)
		delete(C(a, 1));
		C(a, 1) = text(coords(a, 1), coords(a, 2), channels{a}, 'Parent', A);
		set(C(a, 1),...
			'HorizontalAlignment', 'center',...
			'VerticalAlignment', 'middle',...
			'Color', 'w',...    
			'FontUnits', 'normalized',...
			'FontWeight', 'bold');    
	end

	% Save the figure for quick use in the future
	hgsave(C, plotFig);
end
function C = LoadMapping(A, template)
% LOADMAPPING - Loads an existing electrode mapping into the axes being used.
%
%   OUTPUT:
%       C:              [ 68 x 2 HANDLES ]
%                       The electrode patch handle array. The first column is circle patch handles. The second column is text
%                       object handles for electrode name labels.
%
%   INPUTS:
%       A:              HANDLE
%                       A reference to an existing AXES object.
%
%       template:       FILE
%                       A FILE object pointing to a saved handle graphics hierarchy (i.e. using HGSAVE). This is a saved
%                       electrode mapping that will be recolored.
	[C, ~] = hgload(template.ToString(), struct('Parent', A));
	C = reshape(C, [0.5*size(C, 1), 2]);
end