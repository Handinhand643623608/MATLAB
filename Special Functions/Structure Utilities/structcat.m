function cs = structcat(dim, s, varargin)
% STRUCTCAT - Concatenates fields of multiple separate data structures along the specified dimensions.
%
%	STRUCTCAT takes multiple structures with identical field names and layouts and concatenates the data associated with
%	each field together. This function is most useful when dealing with multiple instances of simple structures, such as
%	those used to store different sets of results outputted from the same analysis. Data can then be easily concatenated
%	together to simplify an averaging process or to form a single aggregate data set that is easier to store.
%
%	Any number of structures may be concatenated together so long as their prototypes - the number, names, and ordering
%	of their fields - are identical to one another. Inputting structures that differ in any one of these characteristics
%	will result in an error.
%
%	The dimension over which concatenation occurs can be controlled universally or on a field-by-field basis using the
%	DIM input argument. Additionally, specific structure fields can be omitted from the concatenation process using the
%	OMITFIELDS argument. 
%
%	BASIC USAGE:
% 		As a simple example, consider the following two data structures:
% 
% 				f1 = randi(10, 2, 10);
% 				f2 = randn(2, 10);
% 				s1 = struct('Field1', f1(1, :), 'Field2', f2(1, :));
% 				s2 = struct('Field1', f1(2, :), 'Field2', f2(2, :));
% 
% 		To concatenate the row vectors in the fields of these two separate structures (i.e. to recreate the variables f1
% 		and f2 in a new structure), STRUCTCAT can be applied:
% 
% 				cs = structcat(1, s1, s2);
% 
% 		This concatenates s1.Field1 with s2.Field1 along the first (row) dimension and stores the result in cs.Field1.
% 		This process also occurs for s1.Field2 and s2.Field2.
%
%	CONTROLLING CONCATENATION DIMENSIONS:
% 		Re-using the above example, it is possible to individually control the dimensions over which concatenation
% 		occurs. For example, if concentation of data for the first field should occur along the rows but should occur
% 		along the columns for the second field, the following use of STRUCTCAT can be applied:
% 
% 				cs = structcat([1, 2], s1, s2);
% 
% 		The output cs.Field1 will then be of size [2, 10] while cs.Field2 will be of size [1, 20]. This is most useful
% 		when data structures contain multiple data arrays that are oriented differently or represent completely
% 		different variables. Keep in mind that, when using this syntax, a dimension must be provided for every field of
% 		the structures that concatenation will be performed on.
%
%	OMITTING FIELDS FROM CONCATENATION:
%		Specific fields of the data structures can be omitted from the concatenation process using the OMITFIELDS input
%		argument. For example, if it is not desirable for Field2 from the above example to be concatenated, then
%		STRUCTCAT can be applied as follows:
%
%				cs = structcat(1, s1, s2, 'OmitFields', 'Field2');
%
%		The result is that cs.Field1 will be the size [2, 10] concatenated array the same as before, but cs.Field2 will
%		be the same size [1, 10] array that is found in s1.Field2. In this case, concatenation does not occur, but the
%		initial field data is still copied over to the outputted data structure. This is most useful when concatenating
%		data structures in which one or more fields contain data that is universally applicable to all data (such as
%		time, frequency, sample number, or more generally any data that tends to belong on the x-axis of a plot). These
%		data are often not required to be concatenated together and just need to be present once for all data.
%
%	COMBINATIONS OF USES:
%		Field omission and concatenation dimension control can be combined together. Any fields designated for omission
%		do not count against the number of dimensions (the DIM argument) that must be specified. Instead, dimensions
%		should be specified as if these fields do not exist in the structure. Consider the following example:
%
% 				f1 = randi(10, 2, 10);
% 				f2 = randn(2, 10);
%				f3 = rand(2, 10);
% 				s1 = struct('Field1', f1(1, :), 'Field2', f2(1, :), 'Field3', f3(1, :));
% 				s2 = struct('Field1', f1(2, :), 'Field2', f2(2, :), 'Field3', f3(2, :));
%
%				cs = structcat([1, 2], s1, s2, 'OmitFields', 'Field2');
%
%		Here, Field2 data is not being concatenated. Instead it is directly copied over from s1. Field1 data is
%		concatenated along the first array dimension same as before. However, because Field2 is being omitted, the
%		second of the two dimension specifiers is applied to Field3 data. cs.Field3 will therefore have a size [1, 20]
%		array of random numbers.
%
%	SYNTAX:
%		cs = structcat(dim, s1, s2)
%		cs = structcat(dim, s1, s2, s3,..., sN)
%		cs = structcat(..., 'PropertyName', PropertyValue)
%
%	OUTPUT:
%		cs:					STRUCT
%							The single data structure containing concatenated field data. This structure will always
%							have every field that is present in the inputted structures and each of these fields will be
%							a concatenated array of those structure fields' contents. The dimension that concatenation
%							is performed along depends on the DIM input argument.
%
%							Structure fields that are omitted using the OMITFIELDS argument will still appear in this
%							outputted data structure but will only contain data from the first inputted structure. No
%							concatenation will be performed for these fields.
%
%	INPUTS:
%		dim:				INTEGER or [ INTEGERS ]
%							An integer or vector of integers representing the array dimensions over which concatenation
%							should be performed. If a single integer is provided, concatenation will occur over that
%							dimension for all structure fields. 
%
%							However, if a vector of integers is provided, concatenation will occur along the dimension
%							that corresponds with the list of unsorted structure field names. In this case, the length
%							of this vector must exactly equal the length of the structure field name list after removing
%							fields that are not being concatenated (i.e. through the 'OmitFields' argument).
%
%		s:					STRUCT or [ STRUCTS ]
%							A single structure or vector of structures across which field data will be concatenated
%							together. Multidimensional structure arrays are not supported because the ordering of
%							concatenation might be ambiguous. Any number of structures may be inputted as a
%							comma-separated list (just like ordinary function arguments) or as a vector of individual
%							structures; the outcome is the same either way.
%
%							Each structure inputted to this function must have an identical layout and list of field
%							names, even though the data associated with each field may vary relatively freely. However,
%							the data within each structure field must be able to be concatenated along the specified
%							dimension. Be mindful also of the ordering of structures as they're inputted; this order
%							determines the order of field data concatenation.
%
%	OPTIONAL INPUTS:
%		'OmitFields':		STRING or { STRINGS }
%							A single string or cell array of strings containing fields that should be omitted from the
%							concatenation process. This field will still appear in the outputted data structure but will
%							only contain data from the very first inputted structure (i.e. it will not be a
%							concatenation of data from each separate structure). This is useful for data structures
%							containing data that apply universally to all related structures. By default, no structure
%							fields are omitted.
%							DEFAULT: []

%% CHANGELOG
%	Written by Josh Grooms on 20141208



%% Perform the Concatenation
% Error checks
assert(nargin >= 2, 'At least two structures must be provided in order to concatenate data fields.');
assert(numel(s) == 1 || isvector(s), 'Inputted structures must have a clear ordering in order to be concatenated.');

% Parse the input arguments to seperate options & structures
[s, varargin] = separateStructs(s(:), varargin);
function Defaults
	OmitFields = [];
end
assign(@Defaults, varargin);

% Get the field names of the structures being concatenated
cs = s(1);
fields = fieldnames(cs);

% Remove fields that the user wants omitted & format the concatenation dimension specifiers
if ~isempty(OmitFields); fields(ismember(fields, OmitFields)) = []; end
if (numel(dim) == 1); dim = repmat(dim, length(fields), 1); end
assert(length(dim) == length(fields), 'A concatenation dimension must be specified for each field of the structure.');

% Concatenate the structures
for a = 2:length(s)
	for b = 1:length(fields)
		cs.(fields{b}) = cat(dim(b), cs.(fields{b}), s(a).(fields{b}));
	end
end

end



%% Subroutines
function [s, argcell] = separateStructs(s, argcell)
% SEPARATESTRUCTS - Separates structures from the variable input argument list and returns them both as arrays.
	for a = length(argcell):-1:1
		if isstruct(argcell{a})
			s = cat(1, s, argcell{a});
			argcell(a) = [];
		end
	end
end