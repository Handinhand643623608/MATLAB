function varCell = struct2var(inStruct, exclude)
%STRUCT2VAR Converts a structure into a cell array of name/value pairs for use as input variables.
%   This function converts input structures into a cell vector containing name/value pairs from the
%   structure. Beginning with the first element, every second element along the output cell contains
%   a string representing the field name of the structure. Each of these strings is immediately
%   followed by the value of that field within the structure. STRUCT2VAR does not convert
%   substructures; these are placed within the cell array after the field name it is found beneath
%   in the input structure.
%
%   This function is useful for converting structures into "Name/Value" inputs for other functions.
%
%   SYNTAX:
%   varCell = struct2var(inStruct)
%   varCell = struct2var(inStruct, exclude)
%
%   OUTPUT: 
%   varCell:        A 1-by-2*N cell array of "Name/Value" pairs from the structure. N is the number 
%                   of fields within the first level of the structure. "Name" represents a field
%                   name from the structure, and "Value" represents that field's contents. 
%
%   INTPUT:
%   inStruct:       A structure containing field names and field values that are to be converted
%                   into "Name/Value" pairs inside of the output cell array.
%
%   OPTIONAL INPUT:
%   exclude:        A string or cell array of strings indicating which fields to remove from the
%                   structure before conversion to a cell array. This is useful if the structure
%                   contains fields that are needed by the caller function but cannot be passed on
%                   as input variables. 
%                   DEFAULT: []
%
%   Written by Josh Grooms on 20130702
%       20130711:   Implemented the ability to remove fields from the structure prior to conversion
%                   into a cell array.
%       20130918:   Updated syntax documentation to include the exclusion parameter.


%% Convert the Structure into a Cell Vector of Name/Value Pairs
% Deal with potentially missing input
if nargin == 1
    exclude = [];
end

% Get the field names of the input structure
propNames = fieldnames(inStruct);

% Remove fields from conversion to cell, if called for
if ~isempty(exclude)
    propNames(ismember(propNames, exclude)) = [];
end    

% Pre-allocate the output cell array
varCell = cell(1, 2*length(propNames));

% Convert the structure
b = 1;
for a = 1:length(propNames)
    varCell{b} = propNames{a};
    varCell{b+1} = inStruct.(propNames{a});
    b = b + 2;
end