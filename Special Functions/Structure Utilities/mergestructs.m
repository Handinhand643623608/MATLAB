function S = mergestructs(varargin)
% MERGESTRUCTS - Merges two or more structures into one containing all data fields.
%
%   SYNTAX:
%   S = mergestructs(S1, S2)
%   S = mergestructs(S1, S2,..., Sn)
%   S = mergestructs(..., '-orderfields')
%
%   OUTPUT:
%   S:                  STRUCT
%                       The merged combination of all inputted structures. All fields from each inputted structure will
%                       be present in the output. Field names will be ordered alphabetically if called for, otherwise
%                       they appear sequentially in the order they were added.
%
%   INPUTS:
%   Sn:                 STRUCT
%                       Two or more structures to be combined into the single output structure. Each structure must have
%                       uniquely named fields or an error will be thrown (there's no way to determine which field values
%                       to keep otherwise).
%
%   '-orderfields':     VERBATIM
%                       A string that should be inputted verbatim as it's shown here if the outputted structure should
%                       have its fields ordered alphabetically. Only include this argument at the very end of the
%                       input argument list.
%
%   See also ADDFIELD, STRUCT2VAR

%% CHANGELOG
%   Written by Josh Grooms on 20140929



%% Error Checking
% Ensure at least two structures were inputted
if nargin < 2; error('Two or more structures are required to perform a merge.'); end

% Ensure that each input is a structure
isStruct = cellfun(@(x) isstruct(x), varargin);
if ~all(isStruct)
    error('In order to merge structures, all inputs must themselves be structures.');
end

% Ensure that no structure arrays were inputted
isStructArray = cellfun(@(x) ~(numel(x) == 1), varargin);
if any(isStructArray)
    error('Only single structures may be merged. Arrays of structures are not supported.');
end



%% Merge Structures
% Determine if the user wants the output structure's fields ordered
orderFlag = false;
if strcmpi(varargin{end}, '-orderfields')
    orderFlag = true;
    varargin(end) = [];
end

% Merge structures
S = varargin{1};
for a = 2:length(varargin)
    Sn = varargin{a};
    fields = fieldnames(Sn);
    for b = 1:length(fields); 
        if isfield(S, fields{b});
            error('Structures must all have unique field names in order to be merged.');
        end
        S.(fields{b}) = Sn.(fields{b}); 
    end
end

% Order the fields, if called for
if orderFlag; S = orderfields(S); end



