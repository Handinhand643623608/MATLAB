classdef Interop
% INTEROP - A collection of utility functions that support working with other programming languages.

%% CHANGELOG
%	Written by Josh Grooms on 20150328
	

	%% UTILITIES
	methods (Static)
		
		function PrintArray(x)
		% PRINTARRAY - Formats and prints a numeric array in the MATLAB console window for use with other languages.
		%
		%	PRINTARRAY prints out a version of a MATLAB array that can be used by many other C-style languages, such as C,
		%	C++, and C#. Once printed, the formatted array can be copied and pasted directly into the source code files for
		%	the other language. This is helpful when trying to debug array-specific functions in that language, for which
		%	validating results or outputs may not be as straightforward as it is in MATLAB.
		%
		%	WARNINGS:
		%		- This function currently only prints float (i.e. single-precision) outputs, regardless of the type that is
		%		  inputted. Additional types may be supported in the future, but this is all I need right now.
		%		- Only 2D arrays (i.e. matrices) are supported at this time. Additional dimensions may be supported in the
		%		  future.
		%
		%	SYNTAX:
		%		Interop.PrintArray(x)
		%
		%	INPUT:
		%		x:		[ M x N DOUBLES ]
		%				A numeric matrix of any size to formatted and printed back to the user in the MATLAB console.
		%
		%	See also: fprintf

			assert(ndims(x) == 2, 'Can only format 2D arrays right now.');
	
			nx = size(x, 2);
			ny = size(x, 1);

			numtemplate = '%1.4ff, ';
			linetemplate = ['\t{ ' repmat(numtemplate, 1, nx)];
			linetemplate(end - 1) = [];
			linetemplate = [linetemplate '},\n'];
			mattemplate = repmat(linetemplate, 1, ny);
			
			fprintf(1, ['x = \n\n' mattemplate], x(:));
		end
		
	end
	
end