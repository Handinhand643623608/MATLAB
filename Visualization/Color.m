% COLOR - A value-type primitive class that stores and manages color data.
%
%	Color Properties:
%		R			- The red channel value.
%		G			- The green channel value.
%		B			- The blue channel value.
%
%	Color Constructor:
%		Color		- Constructs a standardized color primitive type.
%
%	Color Static Constructors:
%		Black		- Creates a Color object array of arbitrary size containing only the color black.
%		FromData	- Creates a Color object array that represents a scaled numeric data array.
%		FromInt		- Creates a Color object array from an array of packed color integers.
%		FromRGB		- Creates a Color object array from a numeric RGB array.
%		FromString	- Creates a Color object array from common color codes and name strings.
%		Interpolate - Creates a Color object vector that interpolates between two or more colors.
%		White		- Creates a Color object array of arbitrary size containing only the color white.
%
%	Color Methods:
%		ToArray		- Converts a Color object array into a numeric RGB array whose channel values span the final dimension.
%		ToHex
%		ToInt		- Converts a Color object array into an array of packed 32-bit integers containing the RGB values.
%		ToHSV
%		ToMatrix	- Converts a Color object array into a numeric RGB matrix whose channel values span the columns.
%		ToRGB		- 
%
%	Color Overloads:
%		disp		- Displays information about one or more Color objects in the console window.
%		double
%		image
%
%	See also: BITMAP, COLOR.COLOR, COLOR.FROMDATA, COLOR.FROMRGB, COLORS

%% CHANGELOG
%   Written by Josh Grooms on 20150211
%		20150508:	Overhauled the class documentation to summarize all of the properties and methods that are available.
%					Implemented methods to convert colors to and from packed 32-bit integer values.



%% CLASS DEFINITION
classdef Color < Entity
    
    

    %% DATA
    properties
        R           % The red channel value between [0, 1].
        G           % The green channel value between [0, 1].
        B           % The blue channel value between [0, 1].
    end
    
    properties
		Space	@Colorspace
	end
	
	
    
    %% CONSTRUCTORS
    methods
        function C = Color(varargin)
        % COLOR - Constructs a standardized color primitive type.
		%
		%	SYNTAX:
		%		C = Color(rgb)
		%		C = Color(r, g, b)
		%		C = Color(gray)
		%
		%	OUTPUT:
		%		C:			[ M x 1 COLORS ]
		%					A vector of color objects that correspond with each row of the input array(s). 
		%
		%	INPUTS:
		%		rgb:		[ M x 3 DOUBLES ]
		%					A single flattened RGB value array representing M colors. Each column of this array should
		%					contain the red, green, and blue values of each color, in that order. 
		%
		%		r:			[ M x 1 DOUBLES ]
		%					A vector of separated red channel values for each color. When this input specification is used,
		%					the R, G and B vectors must all be of equal length.
		%	
		%		g:			[ M x 1 DOUBLES ]
		%					A vector of separated green channel values for each color. When this input specification is used,
		%					the R, G, and B vectors must all be of equal length.
		%
		%		b:			[ M x 1 DOUBLES ]
		%					A vector of separated blue channel values for each color. When this input specification is used,
		%					the R, G, and B vectors must all be of equal length.
		%
		%		gray:		[ M x 1 DOUBLES ]
		%					When a single vector of data is provided instead of three, it is interpreted as a grayscale
		%					intensity values. The intensities in this vector will be copied across the red, green, and blue
		%					color channels.
		%
		%	See also: BITMAP, COLOR.FROMDATA, COLOR.FROMRGB, COLORS
			if nargin ~= 0
                [r, g, b] = Color.ParseConstructorInputs(varargin{:});
                ncolors = length(r);
                C(ncolors, 1) = Color();
                
				for a = 1:ncolors
                    C(a).R = r(a);
                    C(a).G = g(a);
                    C(a).B = b(a);
					C(a).Space = Colorspace.RGB;
				end
			else
				C.Space = Colorspace.RGB;
			end
		end
	end
    
	methods (Static)
		function C = Black(varargin)
		% BLACK - Creates a color object array of arbitrary size containing only the color black.
		%
		%	This method is effectively the function ZEROS for color data objects.
		%
		%	See also: COLOR.WHITE, ZEROS
			C = Color.FromRGB(zeros(varargin{:}, 3));
		end
		function C = FromData(x, cmap, clim, nancolor)
		% FROMDATA - Creates an array of scaled color values representing a numeric data array.
		%
		%	COLOR.FROMDATA is effectively an alternate constructor method for the COLOR class that allows shaped arrays of
		%	colors to be created from a data set. This is helpful for pseudocoloring data, which is a visualization approach
		%	that converts data into representative color values to allow for easier interpretation. COLOR.FROMDATA uses the
		%	same scaling method that the function IMAGESC uses.
		%
		%	SYNTAX:
		%		C = Color.FromData(x)
		%		C = Color.FromData(x, cmap)
		%		C = Color.FromData(x, cmap, clim)
		%		C = Color.FromData(x, cmap, clim, nancolor)
		%
		%	OUTPUT:
		%		C:				[ COLORS ]
		%						An array of color objects whose values represent the data in X. This output will always be of
		%						exactly the same size and dimensionality as X.
		%
		%	INPUT:
		%		x:				[ DOUBLES ]
		%						A data array of any size and dimensionality to be converted into representative color values.
		%
		%	OPTIONAL INPUTS:
		%		cmap:			[ COLORS ]
		%						DEFAULT: Colormaps.Jet
		%
		%		clim:			RANGE or [ DOUBLE, DOUBLE ]
		%						A two-element [LOWER, UPPER] bounding vector that controls how the data in X are mapped to
		%						the colors in CMAP. Values in X that are outside of this range are clamped to the nearest
		%						boundary value while values inside the range are unaffected. By default, the minimum and
		%						maximum values in X are used.
		%						DEFAULT: [ min(x(:)), max(x(:)) ]
		%
		%		nancolor:		COLOR
		%						The color that will be used to represent any NaNs present in the data. If no NaNs exist, then
		%						this argument has no effect. By default, NaNs become black in color.
		%						DEFAULT: Colors.Black
		%
		%	See also: BITMAP, COLOR.FROMRGB, COLORS
			assert(isnumeric(x), 'The input data array must be of some numeric type.');
			
			if nargin == 1;	cmap = Colormaps.Jet;			end
			if nargin < 3;	clim = Range.FromData(x);		end
			if nargin < 4;  nancolor = Colors.Black;		end
			
			if ~isa(cmap, 'Color');		cmap = Color(cmap);			end
			if ~isa(clim, 'Range');		clim = Range(clim);			end
			if ~isa(nancolor, 'Color'); nancolor = Color(nancolor); end
			idsNaN = isnan(x);
			
			% FIXME: This method is unbelievably slow given what it's doing. Need to figure out why and fix it.
			
			ncolors = length(cmap);
			x = ( x - clim.Min ) ./ ( clim.Difference );
			x = round(x .* (ncolors - 1)) + 1;
			
			idsc = min(ncolors, x);
			idsc(idsc < 1) = 1;
			idsc(idsc > ncolors) = ncolors;
			
			nx = numel(x);
			c = zeros(nx, 3);
			
% 			C(nx) = Color();
			cmap = cmap.ToArray();

			for a = 1:nx
				c(a, :) = cmap(idsc(a), :);
			end
			
% 			C = cmap(idsc);
			C = Color(c);
			C = reshape(C, size(x));
			C(idsNaN) = nancolor;
		end
		function C = FromInt(i)
		% FROMINT - Creates a Color object array from an array of packed color integers.
		%
		%	SYNTAX:
		%		C = Color.FromInt(i)
		%
		%	OUTPUT:
		%		C:		[ COLORS ]
		%				An array of Color objects representing the colors in the inputted integer array. This method unpacks
		%				the channel values in each integer and restores them to the double-precision fields of Color objects.
		%
		%	INPUT:
		%		i:		[ UINT32 ]
		%				An array of 32-bit unsigned integers whose bit fields contain 8-bit RGBA channel values.
		%
		%	See also: COLOR.TOINT
		
			r = bitand(i, 255);
			g = bitand(bitshift(i, -8), 255);
			b = bitand(bitshift(i, -16), 255);
			
			r = double(r) ./ 255;
			g = double(g) ./ 255;
			b = double(b) ./ 255;
			
			C = Color(r(:), g(:), b(:));
			C = reshape(C, size(i));
		end
        function C = FromRGB(rgb)
		% FROMRGB - Creates an array of color values from a numeric RGB array.
		%
		%	COLOR.FROMRGB is effectively an alternate constructor method for the COLOR class that allows shaped arrays of
		%	colors to be created from a pure RGB number array. This is helpful when a shaped array of RGB values already
		%	exists (i.e. from the CDATA property of graphics objects), but the use of this class is desired. It avoids the
		%	hassle of having to reshape the RGB data to comply with the principal constructor argument requirements. 
		%
		%	SYNTAX:
		%		C = Color.FromRGB(rgb)
		%
		%	OUTPUT:
		%		C:			[ COLORS ]
		%					An array of color objects whose values represent the data in RGB. This output will always be of
		%					exactly the same size as X except over the last dimension, where its size will be 1 instead of 3.
		%
		%	INPUT:
		%		rgb:		[ DOUBLES ]
		%					An array of RGB color values. This may be of any size and dimensionality, but RGB values must
		%					span the last dimension of the array. This means that the size of RGB over the final dimension
		%					must always be exactly 3.
            sz = size(rgb);
            assert(sz(end) == 3, 'RGB values must be correctly ordered and span the last dimension of the input array.');
            
            rgb = reshape(rgb, [], 3);
            C = Color(rgb);
			if (length(sz) > 2)
                C = reshape(C, sz(1:(end - 1)));
			end
		end
		function C = FromString(s)
		% FROMSTRING - Creates color objects from common color codes and name strings.
		%
		%	SYNTAX:
		%		C = Color.FromString(s)
		%
		%	OUTPUT:
		%		C:		[ COLORS ]
		%				An array of color objects whose values represent the colors in S. This output will always be of
		%				exactly the same size and dimensionality as S when S is a cell array of strings.
		%
		%	INPUT:
		%		s:		STRING or { STRINGS }
		%				A string or cell array of strings containing the names or codes of commonly used colors. Cell arrays
		%				may be of any size and dimensionality. See the options listed below for supported input values.
		%
		%				SUPPORTED COLOR CODES & NAMES:
		%					'b' OR 'blue'
		%					'c' OR 'cyan'
		%					'a' OR 'gray'
		%					'g' OR 'green'
		%					'k' OR 'black'
		%					'm' OR 'magenta'
		%					'r' OR 'red'
		%					'w' OR 'white'
		%					'y' OR 'yellow'
		%	
		%	See also: BITMAP, COLOR.FROMDATA, COLOR.FROMRGB, COLORS, STR2RGB
			if ischar(s); s = { s }; end
			C = Color(Color.TranslateColorStrings(s));
			C = reshape(C, size(s));
		end
		function C = Interpolate(n, varargin)
		% INTERPOLATE - Creates a Color object vector that interpolates between two or more colors.
		%
		%	SYNTAX:
		%		C = Color.Interpolate(n, color1, color2)
		%		C = Color.Interpolate(n, method, color1, color2,...)
		%		C = Color.Interpolate(n, method,...)
		%
		%	OUTPUT:
		%		C:			[ N x 1 COLORS ]
		%					A column vector containing the interpolated values between the inputted colors. The number of
		%					colors ultimately present is controlled by the first input argument, N.
		%
		%	INPUTS:
		%		n:			INTEGER
		%					The number of color interpolations to be made. This controls how many colors are present in the
		%					outputted Color object vector.
		%	
		%		color:		[ R, G, B ] or COLOR
		%					Two or more colors between which interpolation will occur. Any number of colors may be inputted
		%					(so long as a minimum of two are provided), but each color must be a separate argument. These may
		%					be specified as numeric RGB vectors, Color objects, or a mixture of the two.
		%
		%	OPTIONAL INPUTS:
		%		method:		STRING
		%					A single string specifying the method by which color interpolation will occur. This parameter is
		%					used directly with the MATLAB-native function INTERP1. See the documentation of that function for
		%					more details.
		%					DEFAULT: 'linear'
		%
		%					OPTIONS:
		%						'cubic'		- Shape-preserving piecewise cubic interpolation.
		%						'linear'	- Linear interpolation between color channel values.
		%						'nearest'	- Nearest neighbor interpolation.
		%						'next'		- Next neighbor interpolation.
		%						'pchip'		- Same as 'cubic'.
		%						'previous'	- Previous neighbor intterpolation.
		%						'spline'	- Piecewise cubic spline interpolation.
		%						'v5cubic'	- The cubic interpolation method from MATLAB 5.
		%
		%	See also: INTERP1
		
			method = 'linear';
			if (nargin > 1 && ischar(varargin{1}))
				method = varargin{1};
				varargin(1) = [];
			end
			
			assert(length(varargin) >= 2, 'Interpolation can only occur between two or more inputted colors.');
			
			for a = 1:length(varargin)
				if isa(varargin{a}, 'Color')
					varargin{a} = varargin{a}.ToMatrix();
				end
			end
			rgb = cat(1, varargin{:});
			
			ncolors = size(rgb, 1);
			cpos = linspace(1, n, ncolors);
			
			r = interp1(cpos, rgb(:, 1), 1:n, method);
			g = interp1(cpos, rgb(:, 2), 1:n, method);
			b = interp1(cpos, rgb(:, 3), 1:n, method);
			
			C = Color([r', g', b']);
		end
		function C = White(varargin)
		% WHITE - Creates a color object array of arbitrary size containing only the color white.
		%
		%	This method is effectively the function ONES for color data objects.
		%
		%	See also: COLOR.BLACK, ONES
			C = Color.FromRGB(ones(varargin{:}, 3));
		end
	end
    
	
    
    %% UTILITIES
    methods (Hidden, Static, Access = protected)
        function [r, g, b]	= ParseConstructorInputs(varargin)
        % PARSECONSTRUCTORINPUTS - Standardizes the many constructor input possibilities into an RGB array.
            switch nargin
                case 1
                    arg = varargin{1};                    
                    if iscellstr(arg);      c = Color.TranslateColorStrings(arg);
                    elseif ischar(arg);     c = Color.TranslateColorStrings({ arg });
                    elseif isnumeric(arg)
                        c = arg;
                        if (size(c, 2) == 1); c = repmat(c, 1, 3); end
                        assert(size(c, 2) == 3, 'Colors must be specified as either grayscale intensities or RGB values.');
                    end
                    r = c(:, 1); g = c(:, 2); b = c(:, 3);
                    
                case 3
                    numcheck = cellfun(@isnumeric, varargin);
                    assert(all(numcheck), 'Inputs for R, G, and B arguments must contain numeric values.');
                    r = varargin{1}; g = varargin{2}; b = varargin{3};
                    veccheck = isvector(r) && isvector(g) && isvector(b);
                    szcheck = ( length(r) == length(g) ) && ( length(g) == length(b) );
                    assert(veccheck && szcheck, 'R, G, and B arguments must all be vectors of equal length.');
                    
                otherwise
                    error('Colors must be specified as either string codes, grayscale intensities, or RGB values.');
            end
		end		
		function c			= TranslateColorStrings(s)
		% TRANSLATECOLORSTRINGS - Translates common color codes and names into RGB values.
			c = zeros(numel(s), 3);
			for a = 1:numel(s)
				switch lower(s{a})
					case {'b', 'blue'}
						c(a, :) = [0 0 1];
					case {'c', 'cyan'}
						c(a, :) = [0 1 1];
					case {'a', 'gray'}
						c(a, :) = [0.5, 0.5, 0.5];
					case {'g', 'green'}
						c(a, :) = [0 1 0];
					case {'k', 'black'}
						c(a, :) = [0 0 0];
					case {'m', 'magenta'}
						c(a, :) = [1 0 1];
					case {'r', 'red'}
						c(a, :) = [1 0 0];        
					case {'w', 'white'}
						c(a, :) = [1 1 1];
					case {'y', 'yellow'}
						c(a, :) = [1 1 0];
					otherwise
						error('Unrecognized color string %s found. See documentation for supported color codes.', s{a});
				end
			end
		end
    end
                
    methods
        function a = ToArray(C)
        % TOARRAY - Converts a Color object array into a numeric RGB array whose channel values span the final dimension.
		%
		%	SYNTAX:
		%		a = C.ToArray()
		%
		%	OUTPUT:
		%		a:		[ DOUBLES ]
		%				An RGB color array whose red, green, and blue channel values span the the final dimension. This array
		%				will always be of exactly the same size as C except over the last dimension, where its size will be 3
		%				instead of 1.
		%
		%	INPUT:
		%		C:		[ COLORS ]
		%				A color object array of any size and dimensionality.
		%
		%	See also: COLOR.TOMATRIX
            szc = size(C);
			if (numel(C) == 1)
				a = double(C);
			else
				a = [ [C.R]', [C.G]', [C.B]' ];
				if (szc(2) > 1)
					a = reshape(a, [szc, 3]);
				end
			end
		end
		function h = ToHex(C)
			
			h = cell(size(C));
			for a = 1:numel(C)
				cbits = round(C(a).ToArray() .* 255);
				h{a} = ['#' rgb2hex(cbits(1), cbits(2), cbits(3))];
			end
		end
		function H = ToHSV(C)
		% TOHSV - Converts color values to HSV color space.
			H = C;
			for a = 1:numel(H)
				switch H(a).Space
					case Colorspace.RGB
						H(a) = Color(rgb2hsv(C(a).ToArray()));
					case Colorspace.HSV
						continue
					otherwise
						error('Cannot currently convert color spaces other than RGB to HSV.');
				end
				H(a).Space = Colorspace.HSV;
			end
		end
		function i = ToInt(C)
		% TOINT - Converts a Color object array into an array of packed 32-bit integers containing the RGB values.
		%
		%	SYNTAX:
		%		i = C.ToInt()
		%
		%	OUTPUT:
		%		i:		[ UINT32 ]
		%				An array of 32-bit unsigned integers representing the colors inputted in C. This array will always be
		%				of exactly the same size and dimensionality as C. Each integer contains in its bit fields the ordered
		%				8-bit red, green, blue, and alpha color channel values from the corresponding Color object in C.
		%				Alpha, which is typically used to represent transparency, is included here to fill out the remaining
		%				8 bits of the 32 bit integer, despite not being a member of these Color objects. It always takes a
		%				value of 1.0 (i.e. 255 in 8-bit color).
		%
		%	INPUT:
		%		C:		[ COLORS ]
		%				An array of Color objects to be converted to unsigned 32-bit integers. This argument can be an array
		%				of any size and dimensionality.
		%
		%	See also: COLOR.FROMINT
		
			r = uint32([C.R]' .* 255);
			g = uint32([C.G]' .* 255);
			b = uint32([C.B]' .* 255);
			a = uint32(255);
			
			i = r;
			i = bitor(i, bitshift(g, 8));
			i = bitor(i, bitshift(b, 16));
			i = bitor(i, bitshift(a, 24));
			
			i = reshape(i, size(C));
		end
		function m = ToMatrix(C)
		% TOMATRIX - Converts a Color object array into a numeric RGB matrix whose channel values span the columns.
		%
		%	SYNTAX:
		%		m = C.ToMatrix()
		%
		%	OUTPUT:
		%		m:		[ N x 3 DOUBLES ]
		%				A numeric RGB color matrix whose red, green, and blue channel values span the second dimension (i.e.
		%				columns). The number of rows present is dictated by the total number of elements in the inputted
		%				object array C.
		%
		%	INPUT:
		%		C:		COLOR or [ COLORS ]
		%				A Color object array of any size and dimensionality to be converted into a numeric RGB matrix. 
		%
		%	See also: COLOR.TOARRAY
			m = ToArray(C(:));
		end
		function R = ToRGB(C)
		% TORGB - Converts color values to RGB color space.
			R = C;
			for a = 1:numel(R)
				switch R(a).Space
					case Colorspace.HSV
						R(a) = Color(hsv2rgb(C(a).ToArray()));
					case Colorspace.RGB
						continue
					otherwise
						error('Cannot currently convert color spaces other than HSV to RGB.');
				end
				R(a).Space = Colorspace.RGB;
			end
		end
	end         
                
    methods
		
		function C = Saturate(C)
			
			for a = 1:numel(C)
				C(a).R = min(C(a).R, 1);
				C(a).G = min(C(a).G, 1);
				C(a).B = min(C(a).B, 1);
			end
		end
		
		function C = Shade(C, n)
			
			for a = 1:numel(C)
				C(a).R = min(C(a).R * n, 1);
				C(a).G = min(C(a).G * n, 1);
				C(a).B = min(C(a).B * n, 1);
			end
		end
	end
	
	
	
	%% MATLAB OVERLOADS
	methods
		function disp(C)
		% DISP - Displays information about one or more Color objects in the console window.
			if (numel(C) > 1)
				fprintf(1, [String.ArraySize(size(C)) ' Array of Color Objects:\n\n']);
			end
			
			for a = 1:numel(C)
				switch C(a).Space
					case Colorspace.HSV
						fprintf(1, '\t[H: %1.4f S: %1.4f V: %1.4f]\n', C(a).R, C(a).G, C(a).B);
					case Colorspace.RGB
						fprintf(1, '\t[R: %1.4f G: %1.4f B: %1.4f]\n', C(a).R, C(a).G, C(a).B);
				end
			end
			
			fprintf(1, '\n');
		end
		function d = double(C)
			d = [C.R, C.G, C.B];
		end
		
		function varargout = image(C, varargin)
			
			assert(ismatrix(C), 'Only two-dimensional color arrays can be used to generate images.');
			
			im = C.ToArray();
			if (size(im, 3) ~= 3)
				im = permute(im, [1 3 2]);
			end
			
			figure;
			assignOutputs(nargout, image(im, varargin{:}));
		end
		
	end
    
	
	
end