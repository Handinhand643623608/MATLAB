% ASSIGN - Assigns inputted name/value function arguments to variables declared in a Defaults block.
%   
%   This function is meant to replace the very old ASSIGNINPUTS function that I wrote a long time ago after discovering the
%   function ASSIGNIN. Although that function has certainly been my most used and relied-upon function for an unprecedented
%   amount of time, it has a few drawbacks that I believe will be corrected through this new approach.
%
%   In short, ASSIGN takes a variable-length list of name/value pairs and assigns them to variables in a function's
%   workspace. This name/value list is frequently seen in function input arguments, especially when many arguments can
%   potentially be used. Such functions employ this scheme to remove the need for correctly ordered long sequences of input
%   arguments, which are impractical to users especially when only a select few optional inputs are being used.
%
%   ASSIGN improves upon the features of that older function by eliminating the need for a structure that hides variable
%   initialization and in turn frequently confuses the MATLAB code analyzer. It also does away with alternative acceptable
%   variable names (which is just bad programming practice) and with the automated formatting of inputted variables (which
%   should be a part of the function logic if desired).
%
%   DEFAULTS BLOCKS:
%       ASSIGN works by determining the names of the variables that are contained within a special default variable blocks,
%       henceforth referred to as Defaults blocks. These blocks are simple nested functions that should be located at or near
%       the beginning of the caller function's logic. Defaults blocks should only contain variable declarations and
%       initializations; there should not be any logic or computation performed inside. Additionally, this function should
%       never be called explicitly in the function that implements it.
%
%   EXAMPLE USAGE:
%       As an example, consider the following MATLAB function:
%
%           function z = myfun(x, y, varargin)
%
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
%       This function is just a simple example, but it should serve to illustrate the purpose of ASSIGN. In this function,
%       the output depends not only on the inputs x and y, which are required variables and must always be provided by the
%       user, but also on the variables A, B, and C, which may or may not be provided. These latter three optional variables
%       can either be designated by the user when calling this function or they may take on their default values that are
%       specified inside of the Defaults block. Combinations of defaults and designated values are also allowed. Thus, when
%       calling this function, any of the following is correct syntax:
%
%           z = myfun(x, y)                             - 'A', 'B', and 'C' have default values
%           z = myfun(x, y, 'A', 100)                   - 'B' and 'C' have default values
%           z = myfun(x, y, 'A', 20, 'B', 30, 'C', 40)  - All optional arguments are designated
%           z = myfun(x, y, 'C', 5e7)                   - 'A' and 'B' have default values
%
%   SYNTAX:
%       assign(defaults, args)
%
%   INPUTS:
%       defaults:       FUNCTION_HANDLE
%                       A function handle referencing the Defaults variable block. This block should be a simple nested
%                       function with no inputs or outputs. It should appear at or near the beginning of the calling
%                       function's logic (i.e. immediately after the function signature or documentation section). 
%
%                       Function handles must be created using the '@' operator. String function names, like those that
%                       can be used with FEVAL, are not supported.
%
%       args:           {...NAME, VALUE,...}
%                       The variable argument list that was inputted to the function. This must be a sequential list of
%                       name/value pairs consisting of a string variable name followed by its associated value. The name
%                       part of this pair must always be a string while the value part may be of any type supported by
%                       MATLAB. Typically, this will just be the "varargin" of the calling function handed off verbatim.
%
%   See also:   ASSIGNIN, ASSIGNINPUTS, VARARGIN

%% CHANGELOG
%	Written by Josh Grooms on 20141120
%       20150211:   Changed the name of this function from ASSIGNTO to ASSIGN (the "to" always bothered me aesthetically).
%                   Added some additional error checks and implemented the ability to input a structure of variables for
%                   assignment instead of always requiring the cell array of name/value pairs. Also got rid of subroutines.



%% FUNCTION DEFINITION
function assign(defaults, args)

    % Formatting checks
    assert(nargin == 2, 'Both a default variable function handle and a list of name/value arguments must be provided.');
    assert(isa(defaults, 'function_handle'), 'The Defaults argument must be a valid function handle.');    
    if isstruct(args); args = struct2var(args); end
    assert(iscellstr(args(1:2:end)), 'Argument names must always be given as strings.');

    % Get the caller workspace variables before the Defaults variables are initialized
    temp = functions(defaults);
    prevars = temp.workspace{1};
    
    % Initialize variables in the Defaults block, then get the post-call workspace variables
    defaults();
    temp = functions(defaults);
    postvars = temp.workspace{1};
    
    % Determine which variables were added after the Defaults block was called
    prenames = fieldnames(prevars);
    postnames = fieldnames(postvars);
    newvars = postnames(~ismember(postnames, prenames));
    
    assert(~isempty(newvars),...
        'No variables in the Defaults block. Ensure that this block was not called prior to assigning input arguments.');

    % Ensure that argument names have corresponding variables that already exist
    memberCheck = all(ismember(args(1:2:end), newvars));
    assert(memberCheck, 'Input argument names must always correspond with default variable names.');

    % Assign values to variables in the caller workspace
    for a = 1:2:length(args)
        assignin('caller', args{a}, args{a + 1});
    end

end