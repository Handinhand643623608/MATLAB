classdef Colormaps
% COLORMAPS - A collection of standard and custom-built color mappings.

%% CHANGELOG
%	Written by Josh Grooms on 20150218


	
	%% COLORMAPS
	methods (Static)
		
		% Standard Colormaps
		function C = Bone(n)
			
			if (nargin == 0); n = 256; end
			C = Color(bone(n));
		end
		function C = Cool(n)
		% COOL - The standard cool color mapping that smoothly varies in hue between cyan and magenta.
		%
		%	See also: COOL
			if (nargin == 0); n = 256; end
			C = Color(cool(n));
		end
		function C = Copper(n)
			
			if (nargin == 0); n = 256; end
			C = Color(copper(n));
		end
		function C = Data
			
			C = [flip(Colormaps.Ice, 1); Colormaps.Fire];
		end
		function C = Gray(n)
			
			if (nargin == 0); n = 256; end
			C = Color(gray(n));
		end
		function C = Hot(n)
		% HOT - The standard hot color mapping that smoothly varies between very dark red and white.
			if (nargin == 0); n = 256; end
			C = Color(hot(n));
		end
		function C = HSV(n)
		% HSV - The standard HSV color mapping that smoothly varies over all hues of color, starting with red.
		%
		%	See also: HSV
			if (nargin == 0); n = 256; end
			C = Color(hsv(n));
		end
		function C = Jet(n)
		% JET - The standard jet colormapping that smoothly varies in hue between dark blue and dark red.
		%
		%	This colormap was the default in MATLAB up through R2014b where it was inexplicably replaced by PARULA.
		%
		%	See also: JET
			if (nargin == 0); n = 256; end
			C = Color(jet(n));
		end
		
		% Custom Colormaps
		function C = Fire(n)
		% FIRE - A color mapping that smoothly varies between dark gray, orange, and dark red.
		%
		%	This colormap is designed as an alternative to HOT. It eliminates the shades of yellow and white from that
		%	mapping in favor of blending in shades of grays.
			if (nargin == 0); n = 256; end
			
			darkRed = Color(0.3, 0, 0);
			red = Colors.Red;
			orange = Colors.Orange;
			gray = Colors.Gray;
			black = Color(0.25, 0.25, 0.25);
			
			C = Color.Interpolate(n, black, gray, orange, red, darkRed);
			C = C.ToRGB();
		end
		function C = Ice(n)
		% ICE - A color mapping that smoothly varies between dark gray, light blue, and dark blue.
		%
		%	This colormap is the complement of the custom mapping FIRE. It is exactly that mapping except that it is flipped
		%	across the RGB color space.
			if (nargin == 0); n = 256; end
			cmap = ToMatrix(Colormaps.Fire(n));
			cmap = flip(cmap, 2);
			C = Color(cmap);			
		end
		function C = LightBlue(n)
			
			if (nargin == 0); n = 256; end
			C = Color.Interpolate(n, Color(0, 0.5, 0.85), Color(0.5, 1, 1));
		end
		function C = LightGray(n)
			
			if (nargin == 0); n = 256; end
			C = Color(linspace(0.35, 0.85, n)');
		end
		function C = LightGreen(n)
			
			if (nargin == 0); n = 256; end
			C = Color.Interpolate(n, Color(0, 0.5, 0), Color(0.75, 1, 0.75));
		end
		function C = LightRed(n)
			
			if (nargin == 0); n = 256; end
			cmap = ToMatrix(Colormaps.LightBlue(n));
			cmap = flip(cmap, 2);
			C = Color(cmap);
		end
		
			
			
		
		function C = Custom(n, varargin)
			
			assert(nargin >= 3, 'At least two colors must be supplied to create a colormap.');
			
			ncolors = 256;
			nsegs = nargin;
			nperseg = ncolors / nsegs;
			
			for a = 1:nsegs
				if isa(varargin{a}, 'Color')
					varargin{a} = Color.ToHSV();
				else
					varargin{a} = rgb2hsv(varargin{a});
				end
			end
			
			C = Color.Interpolate(ncolors, varargin{:});			
			C = C.ToRGB();
			
		end
		
		
	end
	
	
	
	
end