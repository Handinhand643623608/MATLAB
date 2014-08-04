function assignInputs(inStruct, callerVarargin, varargin)
%ASSIGNINPUTS Assigns inputs in the caller function to the input variable structure (overwriting the
%   defaults) and creates variables in the caller's workspace with names/values corresponding to the
%   fields of the input structure.
% 
%   SYNTAX:
%       assignInputs(inStruct, varargin)
%       assignInputs(inStruct, 'varsOnly')
%       assignInputs(inStruct, varargin, 'structOnly')
%       
%       assignInputs(..., 'compatibility', {var1, altVar11, altVar12,..., altVar1N;
%                                           var2, altVar21, altVar22,..., altVar2N;
%                                           varM, altVatM1, altVarM2,..., altVarMN});
%
%       assignInputs(..., {'varToFormat1',...'varToFormatN'}, 'formatExpr')
%   
%   FUNCTION USAGE SYNTAX:
%       function callerFunction(varargin)
%       inStruct = struct(...
%           'varName1', defaultValue1,... 
%           'varName2', defaultValue2,... 
%           'varNameN', defaultValueN);
%       assignInputs(inStruct, varargin, ...)
%
%   EXAMPLE USAGE:
%       function myfun(x, y, varargin)
%       
%       % Initialize default values for necessary function variables
%       inStruct = struct(...
%           'savePath', 'C:\New Folder',...
%           'plotColor', 'b',...
%           'showLegend', true);
%
%       % Generate workspace variables from defaults & user input. Remove any slashes or dots from 
%       % user input for "savePath"
%       assignInputs(inStruct, varargin,...
%           'compatibility', {'savePath', 'path';
%                             'plotColor', 'color'},...
%           {'savePath'}, 'regexprep(varPlaceholder, '(^\.|\\$)', '')')
% 
%   INPUTS:
%   inStruct:           Structure containing default values for variables in the caller function. 
%                       Order & labeling of the fields is not important.
% 
%   callerVarargin:     Variable argument input (varargin) from the caller function. This contains 
%                       name/value pairs that will be used to overwrite defaults in the input
%                       structure and will be used to create variable names in the caller workspace.
%                       OPTIONS: 
%                           varargin           The variable argument list.
%                           'structOnly'       Only overwrite values in the defaults structure.
%                                              Do not create variables in the caller workspace.
%                           'varsOnly'         Only create variables in the caller workspace.
%                                              Do not overwrite values in the defaults structure.
% 
%   OPTIONAL INPUTS:
%   'compatibility':    A cell array of variable name alternatives laid out row-wise. This option
%                       allows the user to input variables to the caller function under a different
%                       name than the corresponding variable that's used throughout the function.
%                       This is helpful in situations where it would be intuitive to give the
%                       function a certain variable name in the "Name/Value" pairings, but doing so
%                       would invoke reserved functions/variables or would generate confusion to the
%                       system. 
%
%                       Any row of this cell array corresponds to a single field name of the
%                       input defaults structure (called inStruct here). The first entry of the row
%                       is the correct variable name (case sensitive) as found in "inStruct". All
%                       other row entries are acceptable alternative variable names (case
%                       insensitive). You do not have to specify compatible variable names for every 
%                       variable.
%
%                       In the following example, "DataPath" is the hypothetical variable used
%                       throughout a function, and the following entries are possible alternatives
%                       that the user might supply ("path" is a reserved system function and may be
%                       confusing to use in an actual function). 
%                       EXAMPLE:
%                           {'DataPath', 'path', 'dir'}
%
%   varsToFormat:       A string or cell array of strings indicating the variables that need to be 
%                       formatted. Allows for more flexible inputs for supracaller functions.
%                       EXAMPLE: 
%                           'varName1'
%                           {'varName1', 'varName2',...}
% 
%   formatExpr:         A single string representing the formatting expression to be applied to 
%                       VARSTOFORMAT. The expression must always contain the string 'varPlaceholder'
%                       indicating where VARSTOFORMAT will go. This should be general and applicable
%                       even if supracaller inputs are completely correct. Examples below represent
%                       tested functionalities. 
%                       EXAMPLE: 
%                           'num2str(varPlaceholder)'
%                           'regexprep(varPlaceholder, '(^\.|\\$)', '')'
%                           'varPlaceholder(:)'
%                           'varPlaceholder = varPlaceholder + 1;
%                           'varPlaceholder(varPlaceholder == 0) = NaN'
% 
%   Written by Josh Grooms on 20130110
%       20130112:   Updated to handle character case mismatches & to apply formatting options to 
%                   caller function input variables.
%       20130113:   Updated on to be able to only assign variables from parameter structures (and
%                   not the parameter structure itself) for the calling function.
%       20130114:   Bug Fix: 'createOnly' wasn't being handled properly
%       20130205:   Expanded functionality to include "compatibility" option, whereby input
%                   variables in the caller function can have their names reassigned. This is useful
%                   in instances when a specific variable name (e.g. "size" or "path") would be
%                   most intuitive, but might block core functionality if actually implemented.
%       20130206:   Rewrote the whole function to be much more efficient & to add the functionality
%                   of creating only the variable structure in the caller function.
%       20130211:   Bug fix where creating variables tried to reassign fields of the input variable
%                   structure.
%       20130214:   Bug fix where a lack of any input in the caller function resulted in errors.
%       20130221:   Bug fix for function attempting to apply formatting options to empty default
%                   structure entries when no corresponding input is given in the caller.
%       20130623:   Improved help & reference section for consistency with other custom functions.
%                   Added documentation about variable compatibility settings. Small improvements to
%                   code (replace checks for booleans with function "any")

%   TODO: Add ability for calling function to require certain "mandatory" input variables


%% Initialize
% Get the fieldnames of the input defaults structure
inFields = fieldnames(inStruct);

% Set up a flag for creating only variables in the caller workspace
varsOnlyFlag = 0;
if ischar(callerVarargin)
    if sum(strcmpi({'createOnly', 'varsOnly'}, callerVarargin)) == 1
        varsOnlyFlag = 1;
        callerVarargin = [];
    end
end

% Set up a flag for using compatibility between variable names
compFlag = 0;
compCheck = strcmpi(varargin, 'compatibility');
if any(compCheck)
    compFlag = 1;
    idxComp = find(compCheck);
    compVars = varargin{idxComp + 1};
    varargin(idxComp:(idxComp+1)) = [];
end

% Set up a flag for creating only an variable structure in the caller workspace
structOnlyFlag = 0;
structOnlyCheck = strcmpi(varargin, 'structOnly');
if any(structOnlyCheck)
    structOnlyFlag = 1;
    varargin(structOnlyCheck) = [];
end


%% Rename Variables with Compatible Alternatives Specified
if ~isempty(callerVarargin) && compFlag
    for i = 1:2:length(callerVarargin)          
        % Determine if alternative variable names have been used. If so, replace them with the correct ones
        [rowAltName, ~] = find(strcmpi(compVars, callerVarargin{i}));
        if any(strcmpi(inFields, callerVarargin{i}))
            continue
        elseif isempty(rowAltName)
            error(['Problem detected with compatibility settings for input variables. '...
                'Check caller function initialization to ensure variable name matches']);
        else
            callerVarargin{i} = compVars{rowAltName, 1};
        end
    end
end


%% Apply Formatting Options to Variables
if ~isempty(varargin)
    for i = 1:2:length(varargin)
        % Get the variables to be formatted & their formatting expressions
        formatVars = varargin{i};
        formatExpr = varargin{i+1};

        % Apply the formatting commands
        for j = 1:length(formatVars)
            % Find where the current variable to format is located in the caller's varargin
            idxCallerVar = find(strcmpi(callerVarargin, formatVars{j})) + 1;
            
            % Look for variable assignments
            varAssignCheck = regexp(formatExpr, '\s=\s', 'ONCE');
            
            % If the variable is not in the caller's varargin, apply formatting to the default value instead
            if isempty(idxCallerVar)
                idxDefaultVar = find(strcmpi(inFields, formatVars{j}));
                % Prevent formatting from being applied to empty defaults & empty inputs
                if isempty(inStruct.(inFields{idxDefaultVar}))
                    break
                else
                    evalExpr = regexprep(formatExpr, 'varPlaceholder', 'inStruct.(inFields{idxDefaultVar})');
                end
            else
                % Replace dummy variable in formatting expression with it's "varagin" entry
                evalExpr = regexprep(formatExpr, 'varPlaceholder', 'callerVarargin{idxCallerVar}');
            end

            % Format the variable & update in caller workspace
            if ~isempty(varAssignCheck)
                eval([evalExpr ';']);
            elseif isempty(idxCallerVar)
                eval(['inStruct.(inFields{idxDefaultVar}) = ' evalExpr]);
            else
                eval(['callerVarargin{idxCallerVar} = ' evalExpr ';']);
            end
        end
    end
end


%% Assign the Variables to the Structure, then Assign All Variables to Caller's Workspace
% Update the input variable structure
if ~varsOnlyFlag && ~isempty(callerVarargin)
    for i = 1:2:length(callerVarargin)
        nameCheck = strcmpi(inFields, callerVarargin{i});
        if any(nameCheck)
            inStruct.(inFields{nameCheck}) = callerVarargin{i+1}; 
        else
            error('Problem detected with function inputs: check name strings to ensure they match possible inputs');
        end
    end
end

% If the caller is not asking for the variable structure only, assign variable names & values
if ~structOnlyFlag
    for i = 1:length(inFields)
        assignin('caller', inFields{i}, inStruct.(inFields{i}));
    end
end

% If the caller is not asking for the variables only, assign the variable structure to the caller
if ~varsOnlyFlag
    assignin('caller', 'inStruct', inStruct)
end