% NUM2RGB - Transforms numeric data arrays into pseudo-colored representations.
%
%	NUM2RGB performs pseudo-coloring (or false-coloring) of a numeric data array, converting data into an easily visualized
%	representation of its original values. This process is identical to the one used in the MATLAB-native function IMAGESC,
%	where 2D data arrays are automatically scaled and mapped onto a range of colors.
%
%	SYNTAX:
%		rgb = num2rgb(x)
%		rgb = num2rgb(x, cmap)
%		rgb = num2rgb(x, cmap, clim)
%		rgb = num2rgb(x, cmap, clim, cnan)
%		[rgb, clim] = num2rgb(...)
%		[rgb, clim, ncolors] = num2rgb(...)
%
%	OUTPUT:
%		rgb:		[ DOUBLES ]
%					An array of RGB colors that represent the data in x. This argument is the pseudo-colored image of x, and
%					as such will always be of exactly the same size as that data array except over the final dimension.
%					Specifically, this output will always have one additional dimension compared to x, which will be of size
%					3 and contain the red, green, and blue color channel values in that ordering. Thus, for example, if x is
%					of size [10, 20, 30], then this output will be of size [10, 20, 30, 3].
%
%	OPTIONAL OUTPUT:
%		clim:		[ DOUBLE, DOUBLE ]
%					The [MIN, MAX] range of the data in x that were mapped to the colors in the Colormap argument. The
%					purpose of this output argument is to return the range of the values in x when clim is determined
%					automatically from the data, potentially eliminating the need to repeatedly calculate these values.
%					However, if the input argument 'clim' is explicitly provided, then this output will be identical, likely
%					making it of little use in that scenario.
%
%		ncolors:	INTEGER
%					The number of color steps present in the 'Colormap' argument. This output is likely of little use when
%					manually specifying the color map as the number of color steps must already be known.
%
%	INPUT:
%		x:			[ DOUBLES ]
%					An array of numeric data to be converted into representative colors.
%
%	OPTIONAL INPUTS:
%		cmap:		[ NC x 3 DOUBLES ] or [ NC x 1 COLORS ]
%					An array of RGB color values representing the pseudo-color mapping used to convert the data in x.
%					Colormaps should be specified as lists of RGB values, but they may also be provided as lists of Color
%					data structures (if available). Smaller values from x will be mapped to the upper portions of this list
%					while larger values will take on colors from the lower portion.
%
%					This argument may be specified as is ordinarily done in MATLAB (e.g. jet(NC), hsv(NC), cool(NC), etc).
%					The number of colors present NC represents how many color steps will exist in the data mapping. Greater
%					numbers of colors result in subtler color differences and a more nuanced pseudo-coloring, but are more
%					computationally expensive.
%					DEFAULT: jet(256)
%
%		clim:		[ DOUBLE, DOUBLE ]
%					The [MIN, MAX] range of the data in x that will be mapped to the colors in Colormap. Values in x that lie
%					outside of this range will be mapped to the nearest color extreme (either the first or last color in the
%					Colormap argument). By default, this range is calculated automatically using the data from x.
%					DEFAULT: []
%
%		cnan:		[ R, G, B ] or STRING or COLOR
%					The designated color of any NaN values found in the input data x. This argument can take the form of an
%					RGB color vector, a string color code, or a Color data structure. By default, NaNs are transformed into
%					the color black.
%					DEFAULT: [0, 0, 0]
%
%	See also: imagesc, str2rgb

%% CHANGELOG
%	Written by Josh Grooms on 20150527



%% FUNCTION DEFINITION
function varargout = num2rgb(x, cmap, clim, cnan)
	
	if (nargin < 4); cnan = [0, 0, 0];	end
	if (nargin < 3); clim = [];			end
	if (nargin < 2); cmap = jet(256);	end
	
	szx = size(x);
	x = x(:);
	idsNaN = isnan(x);
	
	if isa(cmap, 'Color');		cmap = cmap.ToMatrix();		end
	if isempty(clim);			clim = [min(x), max(x)];	end
	if ischar(cnan);			cnan = str2rgb(cnan);
	elseif isa(cnan, 'Color');	cnan = cnan.ToArray();		end
		
	assert(size(cmap, 2) == 3, 'Colormaps must be specified as [ NC x 3 ] arrays of RGB data.');
	
	ncolors = size(cmap, 1);
	cmap = cat(1, cmap, cnan);
	
	idsColors = min(ncolors, round( (ncolors - 1) .* (x - clim(1)) ./ diff(clim) ) + 1);
	
	idsColors(idsColors < 1) = 1;
	idsColors(idsColors > ncolors) = ncolors;
	idsColors(idsNaN) = ncolors + 1;
	
	rgb = cmap(idsColors, :);
	rgb = reshape(rgb, [szx, 3]);
	
	varargout = { };
	assign(varargout, nargout, rgb, clim, ncolors);
	
end