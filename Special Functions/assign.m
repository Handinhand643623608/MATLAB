% ASSIGN - Assigns variable-length input and output argument lists to variables within a function workspace.
%   
%	ASSIGN performs two common tasks in MATLAB. First, it handles the parsing of a variable-length name/value pair (NVP)
%	lists (i.e. 'varargin' function parameters) and their conversion into variables within a function workspace. NVP lists
%	are frequently used to simplify working with functions that accept large numbers of input arguments, many or all of which
%	are optional. They offer the advantage of being able to designate an argument's value explicitly by name as a string,
%	which increases code readability and eliminates the need for arguments to appear in any particular order. Because of
%	this, they are a common sight across functions both built in to MATLAB and custom-written by others.
%
%	The second and related task performed by ASSIGN is to handle variable-length output argument lists (i.e. 'varargout'
%	function parameters). It accomplishes this by automatically populating a cell array with variable values to be returned
%	by the calling function, depending on the number of arguments being requested (determined by the 'nargout' variable).
%
%	This function is meant to replace the very old ASSIGNINPUTS and ASSIGNOUTPUTS functions that I wrote a long time ago
%	after discovering the builtin function ASSIGNIN. Although those functions have certainly been among my most used and
%	relied-upon tools for an unprecedented amount of time, they have some drawbacks that I believe are corrected through this
%	new approach. One improvement made was to eliminate the need for a structure that hides variable initialization and in
%	turn frequently confuses the MATLAB code analyzer. ASSIGN also does away with alternative acceptable variable names
%	(which is just bad programming practice) and with the automated formatting of inputted variables (which should be a part
%	of the function logic if desired). Lastly, by performing the tasks of bold old functions, it reduces the number of
%	external dependencies required by any code that makes use of it.
%
%
%	ASSIGNING NVP LISTS TO WORKSPACE VARIABLES:
%
%		As an example of its usage, consider the following hypothetical MATLAB function:
%	
%           function z = myfun(x, y, varargin)
%
%               function Defaults
%                   A = 10;
%                   B = 20;
%                   C = 30;
%               end
%               assign(@Defaults, varargin);
%
%               z = A*x + B*y + C;
% 
%           end
%
%       This example is somewhat contrived, but it should serve to illustrate the purpose of ASSIGN. In the function MYFUN,
%       the output Z depends not only on the inputs x and y, which are required arguments and must always be provided by the
%       user, but also on the variables A, B, and C, which are optional and may or may not be provided. If any of A, B, and C
%       are not among the inputs of a call to MYFUN, then they should take on some default values that are specified inside
%       of a special nested function block named DEFAULTS in the code above. However, default values can be modified as
%       needed through the use of NVP arguments:
%
%           z = myfun(x, y)                             % 'A', 'B', and 'C' have default values
%           z = myfun(x, y, 'A', 20)					% 'B' and 'C' have default values
%			z = myfun(x, y, 'B', 30, 'C', 40)			% 'A' has a default value
%           z = myfun(x, y, 'A', 20, 'B', 30, 'C', 40)  % All default values are overridden
%			z = myfun(x, y, 'C', 40, 'B', 30, 'A', 20)	% Same as above; ordering of optional variables is unimportant
%
%		The overriding of default values is performed by ASSIGN, which works by changing the values found within the nested
%		function block, henceforth referred to generally as Defaults blocks. The variables within this block can then be used
%		freely throughout any subsequent function code.
%
%
%	DEFAULTS VARIABLE BLOCKS ARE NESTED FUNCTIONS:
%		
%		Defaults blocks are simple nested functions (functions coded inside of other functions) that should be located at
%		or near the beginning of the container function's logic. These blocks should only contain variable initializations;
%		additional logic and computation should be coded elsewhere.
%
%		Although they are technically functions, in general Defaults blocks should not be manually invoked by the user when
%		employing this system. Doing so will restore the original hard-coded default values of any variables included within
%		it, undoing any overrides that were provided as function inputs. Instead, the Defaults block is invoked automatically
%		by ASSIGN, which will typically be called immediately after declaring a Defaults block (see the example code above).
%
%		It may seem strange to use nested functions as default value declarations. Indeed, the older system (see ASSIGNINPUTS
%		if available) accomplished this through the use of structures, which appeared somewhat less alien in source code.
%		When the old system was in place, variables first existed as fields of a default value structure and only appeared on
%		their own in the workspace once ASSIGNIN was called. This sudden and seemingly "magical" appearance of new variables
%		was a great source of confusion to MATLAB's code analyzer, which consistently flagged that sort of behavior as an
%		error (it wasn't, but it fit the pattern of a commonly made programming mistake).
%
%		Nested functions circumvent this problem. They are special in that they allow parent workspaces to both view and
%		modify their variables. Thus, variables can be neatly declared within them and used freely by the parent function.
%		Being able to explicitly declare variables before their use does away with the code analyzer issues that were a
%		constant annoyance when using the previous system.
%
%		Additional syntax highlighting is another advantage of this approach. MATLAB's language parser automatically
%		identifies variables with shared workspace scopes and highlights them using a different color than the one used for
%		ordinary variables, which is just the plain text color (see Preferences/Colors/Programming Tools to view or change
%		this). When writing code, this allows the programmer to easily inspect and trace critical variables controlled by
%		optional input arguments.
%
%
%	ASSIGNING VARIABLES TO OUTPUT ARGUMENT LISTS
%
%		ASSIGN also performs the task of generating variable-length output argument lists. This is usually simpler to deal
%		with than variable-length input lists, but is often tedious and may require the use of loops and/or switch-case
%		statements. This function is meant to alleviate some of that tedium. Consider the following code derived from the
%		earlier example:
%
%           function varargout = myfun(x, y, varargin)
%
%               function Defaults
%                   A = 10;
%                   B = 20;
%                   C = 30;
%               end
%               assign(@Defaults, varargin);
%
%				% Perform some computations the variables here (this is just a toy example, doesn't really matter)
%               z = A*x + B*y + C;
%				C = C + z;
%				D = mean([A, B, C]);
%				
%				varargout = {};
%				assign(varargout, nargout, z, C, D);
%
%			end
%
%		Variable-length output argument lists are often employed when a user may not care about one or more arguments that a
%		function can return, or when the number of outputs requested determines which specific variables are returned. ASSIGN
%		uses the number of requested outputs NARGOUT to populate the list that is ultimately returned:
%
%			z = myfun(...)				% Only z is returned
%			[z, C] = myfun(...)			% Z and C are returned
%			[z, C, D] = myfun(...)		% All possible outputs are returned
%			[C, D, z] = myfun(...)		% No effect (e.g. C will recieve Z's data from the function)
%
%		Unlike the case with input arguments, it is important to keep in mind that outputs cannot be specified by name and
%		thus cannot be re-ordered. They must instead be listed in the same order by which the function returns values. This
%		means that the last entry in the MYFUN calls shown immediately above, while syntactically correct, has no effect on
%		the ordering of outputted data compared to the entry just above it; it will appear in the same order in both cases
%		but may be mislabeled in the latter.
%
%
%   SYNTAX:
%       assign(defaults, argsin)
%		assign(varargout, nargout, argsout)
%
%   INPUTS:
%       defaults:       FUNCTION_HANDLE
%                       A function handle referencing the Defaults variable block. This block should be a simple nested
%                       function with no inputs or outputs. It should appear at or near the beginning of the calling
%                       function's logic (i.e. immediately after the function signature or documentation section).
%
%                       Function handles must be created using the '@' operator. String function names, like those that can
%                       be used with FEVAL, are not supported.
%
%		varargout:		{ }
%						An empty cell array used to store a variable-length output argument list. Unfortunately, this
%						argument must be initialized as an empty array prior to using it with ASSIGN or an error will result.
%						There doesn't currently appear to be any way around this limitation.
%
%       argsin:			{ ...NAME, VALUE,... } or STRUCT
%                       The variable argument list that was inputted to the function. This must be a sequential list of NVPs
%                       consisting of a string variable name followed by its associated value. The name part of this pair
%                       must always be a string while the value part may be of any type supported by MATLAB. Typically, this
%                       entire list will just be the 'varargin' of the calling function handed off verbatim.
%
%		nargout:		INTEGER
%						The number of output arguments being requested from the function in which ASSIGN appears. This can be
%						a value that is calculated in the function code or it can be the variable NARGOUT verbatim, which is
%						a variable that is automatically determined by MATLAB for any function.
%
%		argsout:		{ ..., VALUE,... }
%						A cell array or comma-separated list of all variables that can appear as the output arguments of a
%						function, depending on the NARGOUT parameter. Variables should be listed in the same order that they
%						will appear in the function outputs. If NARGOUT is less than the length of this list, then only the
%						first NARGOUT variables will appear as outputs. NARGOUT values greater than the length of this list
%						will result in errors.
%
%   See also:   ASSIGNIN, ASSIGNINPUTS, NARGIN, NARGOUT, VARARGIN, VARARGOUT

%% CHANGELOG
%	Written by Josh Grooms on 20141120
%       20150211:   Changed the name of this function from ASSIGNTO to ASSIGN (the "to" always bothered me aesthetically).
%                   Added some additional error checks and implemented the ability to input a structure of variables for
%                   assignment instead of always requiring the cell array of name/value pairs. Also got rid of subroutines.
%		20150528:	Implemented the ability to assign arguments to variable-length function output lists (i.e. varargout
%					cells). Also eliminated all external dependencies within this function. Lastly, completely rewrote the
%					documentation for this function to improve clarity and to describe the latest changes.



%% FUNCTION DEFINITION
function assign(target, varargin)
	
	switch class(target)
		
		% Assigning function outputs (i.e. variables to a cell array)
		case 'cell'
			
			% Formatting checks
			nargs = varargin{1};
			varargin(1) = [];
			assert(isnumeric(nargs) && numel(nargs) == 1,...
				'An integer number of arguments is required when assigning function output variables.');
			assert(nargs <= length(varargin), 'Too many output variables were requested from the function.');
			
			% Assign variables to 'varargout'
			outargs = cell(1, nargs);
			assignin('caller', inputname(1), {});
			if nargs > 0
				for a = 1:nargs
					outargs{a} = varargin{a};
				end
				assignin('caller', inputname(1), outargs);
			end
		
		% Assigning function inputs (i.e. variables to a Defaults block)
		case 'function_handle'	

			% Allow inputting of either the whole 'varargin' cell, a comma-separated argument list, or a structure
			if (length(varargin) == 1) && iscell(varargin{1})
				varargin = varargin{1};
			end
			if isstruct(varargin)
				varargin = DecomposeStructure(varargin);
			end
			
			% Formatting checks
			nargs = length(varargin);
			if (nargs > 0)
				assert(mod(nargs, 2) == 0 && iscellstr(varargin(1:2:end)),...
					'Argument lists must be supplied as pairs of string variable names and their corresponding values.');
			end
			
			% Get the caller workspace variables before the Defaults variables are initialized
			temp = functions(target);
			prevars = temp.workspace{1};

			% Initialize variables in the Defaults block, then get the post-call workspace variables
			target();
			temp = functions(target);
			postvars = temp.workspace{1};

			% Determine which variables were added after the Defaults block was called
			prenames = fieldnames(prevars);
			postnames = fieldnames(postvars);
			newvars = postnames(~ismember(postnames, prenames));

			assert(~isempty(newvars),...
				['No variables were found within the Defaults block. Ensure that this block was not called prior to \n'...
				'assigning input arguments.']);

			% Ensure that argument names have corresponding variables that already exist
			memberCheck = all(ismember(varargin(1:2:end), newvars));
			assert(memberCheck, 'Input argument names must always correspond with default variable names.');

			% Assign values to variables in the caller workspace
			for a = 1:2:length(varargin)
				assignin('caller', varargin{a}, varargin{a + 1});
			end
			
		otherwise
			error('Use of the function "assign" with targets of type %s is not supported.', class(target));
		
	end
			
end



%% SUBROUTINES
function c = DecomposeStructure(s)
% DECOMPOSESTRUCTURE - Converts a structure in an equivalent name/value argument cell array.
	fnames = fieldnames(s);
	c = cell(1, length(fnames));
	
	b = 1;
	for a = 1:length(fnames)
		c{b} = fnames{a};
		c{b + 1} = s.(fnames{a});
		b = b + 2;
	end
end