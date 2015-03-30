function outPath = checkExisting(inPath, varargin)
%CHECKEXISTING Checks the input path (file or foler) to see if it already exists in the designated
%   folder structure. If it does, it provides a pop-up dialog box prompting the user for
%   instructions on how to proceed. In this case, the existing file can be overwritten or a new name
%   can be provided for saving the file. 
% 
%   Syntax:
%   outPath = checkExisting(inPath, 'propertyName', propertyValue,...)
% 
%   OUTPUTS:
%   outPath:
% 
%   PROPERTY NAMES:
%   inPath:         A path string of the file that's being checked for existence.
% 
%   ('fileExt'):    A string indicating what type of file is being checked for existence. This isn't
%                   technically necessary, but if able to be provided it speeds up the search
%                   process. 
%                   DEFAULT: 'dir' (something must be searched for, empty arrays are not allowed)
% 
%   Written by Josh Grooms on 20130120
%       20130324:   Bug fix for errors being thrown when called from the base workspace.


%% Initialize
% Initialize defaults structure
inStruct = struct(...
    'fileExt', 'dir');
assignInputs(inStruct, varargin);

% Turn off warnings about directories already existing
warning('off', 'MATLAB:MKDIR:DirectoryExists');

% Get the name of the function that's trying to overwrite the file
functionStack = dbstack;
if strcmpi(functionStack(2).name, 'createNestedFolders')
    try
        % If createNestedFolders is the calling function, go up an extra level (wouldn't be informative)
        functionName = functionStack(3).name;
    catch err
        if ~strcmp(err.identifier, 'MATLAB:badsubscript')
            % If the base workspace is calling this, don't error out. Otherwise, rethrow the error
            rethrow(err)
        else
            functionName = functionStack(2).name;
        end
    end
else
    functionName = functionStack(2).name;
end

%% Check Input Path to See if it Already Exists
switch exist(inPath, fileExt)
    case {0, 1}
        % Create the file
        outPath = inPath;
        
    % If it does, give the user the option to correct this
    otherwise
        existFlag = true;
        while existFlag
            % Get the name of the file that's about to be overwritten
            folderToOverwrite = regexp(inPath, '([^\\]*)$', 'match');

            % Generate a dialog box for user input on whether or not to overwrite the file
            dlgStatement = ['Directory "' folderToOverwrite{1} '" already exists.'];
            overwriteButton = questdlg({dlgStatement; 'Overwrite contents of existing folder?'},...
                                        functionName, 'Yes', 'No', 'Cancel Program', 'No');

            % Check the answer that's given
            if strcmp(overwriteButton, 'No')
                
                % If "No", give the user the opportunity to create another folder
                newFile = inputdlg('Input a New Directoy to Create:', 'Folder Name Input');
                inPath = regexprep(inPath, folderToOverwrite, newFile);
                
                % Check if this new folder exists
                if exist(inPath, fileExt)
                    % If it does, re-loop back through to give the user the option to rename it
                    continue
                else
                    % Otherwise, create the folder
                    existFlag = false;
                end

            elseif strcmp(overwriteButton, 'Cancel Program')
                
                % If the user decides to cancel execution, error out of all programs
                error('User aborted file creation in function %s', functionName)
            
            else
                % The user selected "Yes", so overwrite the file
                existFlag = false;
            end
        end
        
        % Create the file
        outPath = inPath;
end
             
