classdef Bitmap < handle & Entity
% BITMAP - A class that stores and manages an array of RGB pixel values.

%% CHANGELOG
%	Written by Josh Grooms on 20150211
	
	
    
	%% DATA
	properties
		CLim		@Range	% The lower and upper value limits of the color mapping in data units.
        Colormap    @Color  % The sorted list of colors that are mapped to the data values.
		NaNColor	@Color  % 
    end
    
    properties (SetAccess = protected)
        Size
    end
	
	properties (Dependent)
		Height              % The height of the bitmap in pixels.
		Width               % The width of the bitmap in pixels.
	end
	
	properties (Access = protected)
		BMP
		Data
        DataRange	@Range
        HasNaNs		@logical
		NeedsUpdate	@logical
	end
	
	
	
	%% PROPERTIES
	methods
        % Get methods
		function h = get.Height(B)
			h = B.Size(1);
        end
        function w = get.Width(B)
			w = B.Size(2);
        end
        
        % Set methods
        function set.CLim(B, clim)
			if ~isa(clim, 'Range'); clim = Range(clim); end
            for a = 1:numel(B)
                B(a).CLim = clim;
                B(a).NeedsUpdate = true;
            end
        end
        function set.Colormap(B, cmap)
            for a = 1:numel(B)
                B(a).Colormap = cmap;
                B(a).NeedsUpdate = true;
            end
        end
        function set.NaNColor(B, color)
            for a = 1:numel(B)
                B(a).NaNColor = color;
                if (B(a).HasNaNs); B(a).NeedsUpdate = true; end
            end
		end
	end
	
	
	
	%% CONSTRUCTOR
	methods
		function B = Bitmap(x, varargin)
        % BITMAP - Constructs a bitmap object out of a two-dimensional data matrix.
        %
        %   SYNTAX:
		%		B = Bitmap(x)
		%		B = Bitmap(x, 'PropertyName', PropertyValue,...)
        %
        %   OUTPUT:
        %		B:				BITMAP
		%
        %   INPUTS:
		%		x:				[ MX x N DOUBLES ]
        %
        %   PROPERTIES:
		%		CLim:			[ DOUBLE, DOUBLE ]
		%
		%		Colormap:		[ MC x 3 DOUBLES ]
		%
		%		NaNColor:		COLOR
        
			assert(ismatrix(x), 'The input array must be a 2D data matrix.');
			assert(isnumeric(x), 'The input data array must be of numeric type.');

			r = Range(x);
			function Defaults
				CLim        = r;
				Colormap    = Colormaps.Jet;
				NaNColor    = Colors.Black;
			end
			assign(@Defaults, varargin);

			B.Data = x;
			B.Size = size(x);

			x = x(:);
			B.DataRange = r;
			B.HasNaNs = any(isnan(x));

			B.CLim      = CLim;
			B.Colormap  = Colormap;
			B.NaNColor  = NaNColor;

			B.NeedsUpdate = true;
		end
	end
	
	methods (Static)
		function B = Black(m, n)
		% BLACK - Constructs a black-colored bitmap object of arbitrary size.
			if (nargin == 1);	n = m;	end
			B = Bitmap(nan(m, n), 'NaNColor', Colors.Black);
		end
		function B = FromFile(F)
			B = Bitmap.Black(1);
			B.NotYetImplemented();
		end
	end
	
	
	
	%% UTILITIES
    methods (Hidden, Access = private)
        function AssertEqualDimensions(B)
        % ASSERTEQUALDIMENSIONS - Ensures that bitmap dimensions are equivalent before performing certain operations.
            if (numel(B) > 1)
                hchk = length(unique([B.Height])) == 1;
                wchk = length(unique([B.Width])) == 1;
                if ~(hchk && wchk)
                    fname = dbstack(1);
                    e = MException('Bitmap:MismatchedDimensions',...
                        'Image dimensions must all be equivalent when invoking %s on an array of bitmaps.', fname.name);
					throwAsCaller(e);
                end
            end
        end
        function Update(B)
        % UPDATE - Converts the data array to an RGB bitmap and applies any object property changes that have occurred.
            for a = 1:numel(B)
                if (B(a).NeedsUpdate)
					B(a).BMP = Color.FromData(B(a).Data, B(a).Colormap, B(a).CLim, B(a).NaNColor);
                end
            end
        end
        
        function R = GetDataRange(B)
        % GETDATARANGE - Gets the minimum and maximum data values present in an array of bitmap objects.
			R = Range(B.DataRange);
        end
    end
    
	methods
		function r = ToArray(B)
        % TOARRAY - Converts the bitmap object to an RGB value array.
            B.AssertEqualDimensions();
			B.Update();
			r = B.BMP.ToArray();
		end
        function C = ToColor(B)
		% TOCOLOR - Convers the bitmap object to an array of pixel colors.
			B.AssertEqualDimensions();
            B.Update();
			C = B.BMP;
		end
	end
	
	
	
	%% MATLAB OVERLOADS
	methods
		
		function H = image(B, varargin)
		
			B.AssertSingleObject();
			H = image(B.ToArray, varargin{:});
% 			axis equal;
		end
		
	end
	
	
	
end