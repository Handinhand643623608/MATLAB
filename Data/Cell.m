% CELL - A collection of utility functions that specifically operate on or produce cell arrays.
%
%	Cell Methods:
%		Isa			- Determines whether or not elements of a cell array are of a specific type.
%		IsEmpty		- Determines whether or not elements of a cell array are empty.
%		Reduce
%		ToStruct

%% CHANGELOG
%	Written by Josh Grooms on 20150225
%		20150511:	Implemented two new utilities, ISA and ISEMPTY, for testing cell arrays.



%% CLASS DEFINITION
classdef Cell
	
	
	methods (Static)
		
		
		function b = Isa(c, class)
		% ISA - Determines whether or not elements of a cell array are of a specific data type.
		%
		%	SYNTAX:
		%		b = Cell.Isa(c, class)
		%
		%	OUTPUT:
		%		b:			[ BOOLEANS ]
		%					A Boolean array containing TRUE values wherever elements of C are of type CLASS and FALSE values
		%					otherwise. This argument will always be exactly the same size and dimensionality as the input
		%					array.
		%
		%	INPUTS:
		%		c:			{ ANYTHING }
		%					A cell array containing any data type to be tested.
		%	
		%		class:		STRING
		%					A string specifying the class name to be used when performing the data type test.
			assert(ischar(class), 'Class names must be specified as strings.');
			b = cellfun(@(x) isa(x, class), c);
		end
		function b = IsEmpty(c)
		% ISEMPTY - Determines whether or not elements of a cell array are empty.
		%
		%	The builtin function ISEMPTY is typically used to test for the presence of empty variables or array elements.
		%	However, its application to cells behaves a little differently. Because any given cell array is itself wrapped in
		%	a single cell, the native ISEMPTY only tests the outermost cell for emptiness, which is often not what is needed.
		%	
		%	This function tests each element of an inputted cell array for empty values and returns a Boolean array that is
		%	the same size as the input argument. It is essentially a shortcut for having to call CELLFUN each time one wishes
		%	to perform that logical test on cells.
		%
		%	SYNTAX:
		%		b = Cell.IsEmpty(c)
		%
		%	OUTPUT:
		%		b:		[ BOOLEANS ]
		%				A Boolean array containing TRUE values wherever elements of C are empty and FALSE values otherwise.
		%				This argument will always be exactly the same size and dimensionality as the input array.
		%
		%	INPUT:
		%		c:		{ ANYTHING }
		%				A cell array containing any data type. Often this will be a cell array of strings because MATLAB
		%				natively supports sensible array formation for most other types. 
		%
		%	See also: CELLFUN, ISEMPTY
			b = cellfun(@isempty, c);
		end
		
		function y = Reduce(x)
			
			
		end
		
		function s = ToStruct(c)
			
			assert(isnvp(c), 'Converting a cell to a structure requires a fieldname/value paired list.');
			s = struct(c{:});
		end
		
	end
	
	
	
	%% ERROR HANDLING
	methods (Hidden, Static, Access = private)
		
		function AssertCell(c)
		% ASSERTCELL - Throws a standardized exception if the input argument is not a cell array.
			if ~iscell(c)
				fname = dbstack(1);
				throwAsCaller(Cell.NotACellException(inputname(1), fname.name));
			end
		end
		function AssertCellContents(c)
		% ASSERTCELLCONTENTS - Throws a standardized exception if the input argument is not a cell array of cells.
			if ~Cell.Isa(c, 'cell')
				fname = dbstack(1);
				throwAsCaller(Cell.CellContentsException(inputname(1), fname.name));
			end
		end
		
		function E = CellContentsException(vname, fname)
			
			E = MException('Cell:CellContents', 'The argument %s in %s must be a cell array of cells.', vname, fname);
		end
		function E = NotACellException(vname, fname)
			
			E = MException('Cell:NotACell', 'The argument %s in %s must be a cell array.', vname, fname);
		end
		
	end
	
	
	
	
end