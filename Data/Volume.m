classdef Volume < Entity
% VOLUME - A class that stores and manages volumetric data array.

%% CHANGELOG
%	Written by Josh Grooms on 20150212

	
	
	%% DATA
	properties (SetAccess = protected)
		HasNaNs		@logical
		Size
	end
	
	properties (Dependent)
		Depth		@uint64			% The size of the volume along the 3rd direction.
		Height		@uint64			% The size of the volume along the 1st dimension.
		Max			@double			% The maximum value present in the volume.
		Min			@double			% The minimum value present in the volume.
		Width		@uint64			% The size of the volume along the 2nd dimension.
	end
	
	properties (Hidden, Access = protected)
		Data
		DataRange	@Range
		VoxelSize
	end
	
	
	
	%% PROPERTIES
	methods
		function d = get.Depth(V)
			d = V.Size(3);
		end
		function h = get.Height(V)
			h = V.Size(1);
		end
		function m = get.Max(V)
			m = V.DataRange.Max;
		end
		function m = get.Min(V)
			m = V.DataRange.Min;
		end
		function w = get.Width(V)
			w = V.Size(2);
		end
	end
	
	
	
	%% CONSTRUCTORS
	methods
		function V = Volume(x)
		% VOLUME - Constructs a standardized volumetric data array.
			assert(ndims(x) <= 3, 'Volumetric arrays must not contain more than three dimensions of data.');
			assert(isnumeric(x), 'The input data array must of numeric type.');
			
			V.Data = x;
			
			[sx, sy, sz] = size(x);
			V.Size = [sx, sy, sz];
			
			x = x(:);
			V.DataRange = Range(x);
			V.HasNaNs = any(isnan(x));
		end
	end
	
	methods (Static)
		function V = NaN(varargin)
		% NAN - Creates a volumetric array of NaN values.
			V = Volume(nan(varargin{:}));
		end
		function V = Ones(varargin)
		% ONES - Creates a volumetric array of one values.
			V = Volume(ones(varargin{:}));
		end
		function V = Series(x)
		% SERIES - Creates a vector or series of volumes.
			assert(ndims(x) <= 4, 'Volumetric array series can only be constructed from data with four or fewer dimensions.');
			[nx, ny, nz, nv] = size(x);
			V = repmat(Volume.Zeros(nx, ny, nz), nv, 1);
			for a = 1:nv; V(a) = Volume(x(:, :, :, a)); end
		end
		function V = Zeros(varargin)
		% ZEROS - Creates a volumetric array of zero values.
			V = Volume(zeros(varargin{:}));
		end
	end
	
	
	
	%% UTILITIES
	methods
		function a = ToArray(V)
		% TOARRAY - Converts the volume object into a numeric 3D array.
			a = V.Data;
		end
		function B = ToBitmap(V, slices, clim)
		% TOBITMAP - Converts the specified slices of the volumetric array to bitmap objects.
			V.AssertSingleObject();
			if (nargin == 1);	slices = 1:V.Depth;				end
			if (nargin < 3);	clim = Range.FromData(V.Data);	end
			ns = length(slices);
			B = repmat(Bitmap.Black(V.Height, V.Width), ns, 1);
			for a = 1:ns
				B(a) = Bitmap(V.Data(:, :, slices(a)), 'CLim', clim);
			end
		end
		function ToIMG(V, path)
		% TOIMG - Converts a series of volumetric arrays to NIFTI IMG files saved to the specified path.
			if ~exist(path, 'dir'); mkdir(path); end
			if isa(path, 'Path'); path = path.ToString(); end
			for a = 1:numel(V)
				ctfname = sprintf('%s/%03d.img', path, a);
				writeimg(ctfname, V(a).ToArray(), 'double', [2, 2, 2], V(a).Size);
			end
		end
		function m = ToMatrix(V)
		% TOMATRIX - Flattens the volume object into a 2D matrix.
			m = reshape(V.Data, [], V.Depth);
		end
		
		
	end
	
	
	
	%% MATLAB OVERLOADS
	methods
		function disp(V)
			
			if (numel(V) == 1)
				fprintf(1,...
					['\n',...
					 'Volumetric Array Object:\n\n',...
					 '\tDataSize: %s\n\n',...
					 '\t  Height: %d\n',...
					 '\t   Width: %d\n',...
					 '\t   Depth: %d\n\n',...
					 '\t HasNaNs: %s\n',...
					 '\tMinValue: %f\n',...
					 '\tMaxValue: %f\n\n'],...
					 String.ArraySize(V.Size),...
					 V.Height,...
					 V.Width,...
					 V.Depth,...
					 String.Boolean(V.HasNaNs),...
					 V.Min,...
					 V.Max);
			else
				fprintf(1, '%s Array of Volume Objects\n\n', String.ArraySize(size(V)));
			end
		end
		function V = flip(V, dim)
		% FLIP - Flips the volume about the specified dimension.
		%
		%	See also: FLIP
			if (nargin == 1); dim = 1; end
			V.Data = flip(V.Data, dim);
		end
		function b = isnan(V, flatten)
		% ISNAN - Gets the Boolean indices of any NaNs present in the data and optionally flattens them into a vector.
			if (nargin == 1); flatten = false; end
			if (V.HasNaNs);	b = isnan(V.Data);
			else b = false(V.Size); end
			if flatten; b = b(:); end
		end
		function V = permute(V, order)
		% PERMUTE - Rearranges the dimensions of the volume according to the inputted ordering.
		%
		%	See also: PERMUTE
			V.Data = permute(V.Data, order);
			V.Size = size(x);
		end
		
		% Operators
		function V = uminus(V)
		% UMINUS - The unary minus operator that multiplies each value in a data array by negative one.
			V.Data = uminus(V.Data);
			V.DataRange = Range(V.Data);
		end
	end
	
	
	
	
	
	
	
	
end