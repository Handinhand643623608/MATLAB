function S = addfield(S, varargin)
% ADDFIELD - Add new fields to a structure.
%   
%
%   SYNTAX:
%   S = addfield(S, fieldName, fieldValue,...)
%   S = addfield(S, nameValueCell)
%   S = addfield(..., '-orderfields')
%
%   OUTPUT:
%   S:                  STRUCT
%                       The inputted structure with the additional fields added in. Field names will be ordered
%                       alphabetically if called for, otherwise they appear sequentially in the order they were added.
%
%   INPUTS:
%   S:                  STRUCT
%                       A single structure that is to have new fields and associated values appended to it.
%
%   fieldName:          STRING
%                       The name of a new structure data field as it will appear in the outputted structure. Any number
%                       of field names can be added to the structure by specifying a new name for every inputted value
%                       (i.e. use name/value pairs).
%
%   fieldValue:         ANYTHING
%                       The value that the new data field (designated by the FIELDNAME parameter) will hold. This can be
%                       any type of data that MATLAB uses. Any number of field values can be added to the structure by
%                       specifying a new value for every inputted name (i.e. use name/value pairs).
%
%   nameValueCell:      {..., STRING, VALUE,...}
%                       A cell containing any number of name/value pairs to be added to the structure. This is an
%                       alternative way of adding fields to a structure that would typically be useful when 
%                       programmatically adding a lot of new data to an existing structure.
%
%   '-orderfields':     VERBATIM
%                       A string that should be inputted verbatim as it's shown here if the outputted structure should
%                       have its fields ordered alphabetically. Only include this argument at the very end of the input
%                       argument list; otherwise it will be included as a field name in the outputted structure.
%
%   See also STRUCT2VAR

%% CHANGELOG
%   Written by Josh Grooms on 20131209
%       20140929:   Filled in the documentation section of this function.



%% Initialize
% If the input structure is an empty array, initialize a structure
if isempty(S); S = struct(); end

% Determine if the user wants the output structure's fields ordered
orderFlag = false;
if strcmpi(varargin{end}, '-orderfields')
    orderFlag = true; 
    varargin(end) = []; 
end

% Determine if fields are given as a cell or as field/value pairs
if iscell(varargin{1})
    fields = varargin{1};
    vals = cell(1, length(fields));
else
    fields = varargin(1:2:end);
    vals = varargin(2:2:end);
end


%% Add Fields & Values to the Structure
% Add fields & values
for a = 1:numel(S)
    for b = 1:length(fields)
        S(a).(fields{b}) = vals{b};
    end
end

% Order the fields, if called for
if orderFlag; S = orderfields(S); end