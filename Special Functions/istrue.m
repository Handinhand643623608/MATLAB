function booVal = istrue(x, conditional, dim)
%ISTRUE Checks whether or not an input is true or false, with lots of flexibility.
%   This function accepts logical, string, and cell-type inputs and converts them to Booleans by
%   by compariing them to a library of equivalently TRUE values. ISTRUE can return either an array
%   of Booleans or subject an input array to a list of conditional options. It can also operate only
%   along specific dimensions of the input array.
%
%   Values that are equivalently TRUE are:
%       'activate' AND 'active'
%       'enable' AND 'enabled'
%       'true' AND true AND 1 AND ~0
%       'yes' AND 'y'
%
%   SYNTAX:
%   booVal = istrue(x)
%   booVal = istrue(x, conditional)
%   booVal = istrue(x, conditional, dim)
%
%   OUTPUT:
%   booVal:         A Boolean or array of Booleans indicating whether or not the input conditions
%                   are met. If X is the single input, ISTRUE outputs an array the same size as X
%                   with Boolean elements corresponding to the input. If a conditional is specified
%                   without specifying DIM, ISTRUE outputs a single Boolean value. If all three
%                   inputs are supplied, the output is the same size as the input, except over DIM
%                   where it will be of size 1.
%
%   INTPUT:
%   x:              The input array to be converted into Boolean(s) and subject to any conditionals.
%
%   OPTIONAL INPUT:
%   conditional:    A string specifying the conditionals that the user wants to apply to an array of
%                   Booleans. This is only applicable to array inputs. This may be a string from the
%                   options below or an index into the Boolean array to determine whether or not a
%                   specific entry is true or false. If a dimension is specified for this function,
%                   these conditionals operate only along that specific dimension of the input
%                   array.
%                   DEFAULT: []
%                   OPTIONS:
%                       idx     - This specific index of the input array must be true for ISTRUE to
%                                 return TRUE.
%
%                       'all'   - All elements of the input array or along a specific dimension must
%                                 be true for ISTRUE to return TRUE.
%                       'any'   - Any elements of the input array or along a specific dimension must
%                                 be true for ISTRUE to return TRUE.
%                       'none'  - All elements of the input array or along a specific dimension must
%                                 be false for ISTRUE to return TRUE.
%                       'one'   - A single element of the input array or along a specific dimension
%                                 must be true for ISTRUE to return TRUE.
%           
%   dim:            A scalar indicating the dimension along the input array that any input
%                   conditionals will work on. If a conditional is specified without specifying DIM,
%                   the input array is flatted to a vector and only a single Boolean is outputted.
%                   DEFAULT: []
%
%   Written by Josh Grooms on 20130712
%       20130728:   Updated help & reference section.


%% Initialize
% Deal with a missing input parameters
if nargin == 1
    conditional = [];
elseif nargin == 2
    x = x(:); dim = 1;
end

% Initialize the list of possible true entries
trueList = {'activate', 'active', 'enable', 'enabled', 'on', 'true', 'yes', 'y'};


%% Convert to a Boolean or Array of Booleans
% Do the conversion
if islogical(x)
    booVal = x;
else
    if ischar(x)
        booVal = ismember(lower(x), trueList);
    elseif iscell(x)
        booVal = cellfun(@(x) ismember(lower(x), trueList), x);
    elseif isnumeric(x)
        booVal = logical(x);
    else
        error('Input x is of unknown type. Inputs must be a string, cell array, or numeric');
    end
end
    
% Conditionals are only applicable to arrays of Booleans
if numel(booVal) > 1 && ~isempty(conditional)
    if isnumeric(conditional)
        % If a numeric conditional is given, use this as an index into the array
        booVal = booVal(conditional);
    else
        % Otherwise, implement the conditional
        switch lower(conditional)
            case 'none'
                booVal = ~any(booVal, dim);
            case 'any'
                booVal = any(booVal, dim);
            case 'all'
                booVal = all(booVal, dim);
            case 'one'
                booVal = sum(booVal, dim);
                booVal = booVal == ones(size(booVal));
        end
    end
end