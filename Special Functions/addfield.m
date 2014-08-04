function S = addfield(S, varargin)
%ADDFIELD Add fields to a structure array.
%   
%
%   SYNTAX:
%   S = addfield(S, 'field', fieldValue,...)
%   S = addfield(S, FIELDS)
%   S = addfield(..., 'orderfields')
%
%   OUTPUT:
%   S:
%
%   INPUTS:
%   S:
%
%   'field':
%
%   fieldValue
%
%   FIELDS:
%
%   'orderfields':
%   
%   Written by Josh Grooms on 20131209


%% Initialize
% If the input structure is an empty array, initialize a structure
if isempty(S); S = struct(); end

% Determine if the user wants the output structure's fields ordered
orderFlag = false;
if strcmpi(varargin{end}, 'orderfields')
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