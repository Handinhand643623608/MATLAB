function S = emptystruct(varargin)
% EMPTYSTRUCT - Creates a single empty structure with pre-initialized field names.
%   This function initializes a single new structure with a list of field names whose corresponding values are always
%   empty arrays. This is useful for preallocating data structures whose field names, but not the associated values or
%   dimensionalities of the values, are known at design-time. This manner of preallocation avoids the overhead incurred
%   through dynamic structure field creation at run-time. As such, it is a quick shortcut to the alternative methods of
%   specifying empty arrays in the MATLAB-native STRUCT constructor or using the CELL2STRUCT function. 
%
%   Field names of the outputted structure are specified as individual input arguments to this function, with support
%   for a practically unlimited number of field names. They may also be specified using a cell array, so long as that
%   cell array is first converted into a comma-separated list during the function call. The following example uses both 
%   approaches to generate identical empty structures S1 and S2:
%
%   % Input field names as function arguments
%   S1 = emptystruct('FirstField', 'SecondField', 'ThirdField');
%
%   % Create a cell array of field names & convert them to an argument list during the function call
%   fieldCell = {'FirstField', 'SecondField', 'ThirdField'};
%   S2 = emptystruct(fieldCell{:});
%
%   Using a cell array of names is useful when programmatically generating large data structures whose fields correspond
%   with variables or the names of data fields from other structures/objects. 
%
%   SYNTAX:
%   S = emptystruct(name1, name2,..., nameN)
%
%   OUTPUT:
%   S:          STRUCT
%               A single structure containing fields whose named according to the inputs. The value of each of these
%               fields will always be empty.
%
%   INPUTS
%   nameN:      STRING
%               A single string that will become the name of one of the outputted structure's fields. Any number of
%               names may be inputted in this fashion by providing each field name as an individual function argument.

%% CHANGELOG
%   Written by Josh Grooms on 20141009



%% Initialize an Empty Structure
% If no inputs are provided, return a completely empty structure
if nargin == 0; 
    S = struct(); 
    return; 
end

% Get a cell array of field names
if (any(cellfun(@iscell, varargin)))
    error('Cell arrays cannot be used as an input to this function.');
end
fieldNames = varargin;

% Error check
if (~all(cellfun(@ischar, fieldNames)))
    error('Structure field names must be inputted as strings. Other types are not allowed.');
end

% Generate the empty structure
S = cell2struct(cell(length(fieldNames), 1), fieldNames, 1);