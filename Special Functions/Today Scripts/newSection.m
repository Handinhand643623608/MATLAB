function newSection
%NEWSECTION Creates a new time section inside of today scripts.
%   This function creates a new section inside of today's working script that is titled with the time of creation. It
%   also automatically initializes some commonly used variables at the top of the section for convenience.
%
%   NEWSECTION only works on Today Scripts named with the current date (in YYYYMMDD format). The "current date" is
%   whatever day the system time evaluates to when NEWSECTION is run. It will not work on scripts with differently
%   formatted file names or scripts from past dates.
%   
%   This function takes no input arguments, returns nothing, and can only be used from within the Today Script itself.
%   
%   INSTRUCTIONS:
%       1. Open and view the Today Script named with the current date.
%       2. Click on the empty line in the script where a new time section is to be created.
%       3. Type this function's name, "newSection" without quotes, on the line.
%       4. Highlight the function's name, right-click, and select "Evaluate Selection" from the context menu.
%           4a. The default shortcut for selection evaluation is the F9 keyboard key.

%% CHANGELOG
%   Written by Josh Grooms on 20140627
%       20140630:   Added a parameter for naming data files under the first time section.
%       20141008:   Updated for compatibility with changed infraslow data dependent properties of the Paths object.
%                   Added an automatic comment placement for retrieving data file references. Added semicolons to the
%                   ends of variables listed at the beginning of the section. Made the analysis stamp an empty string
%                   instead of an incomplete line of code.



%% Create a New Today-Script Section
% Initialize important file name & time strings
strDate = datestr(now, 'yyyymmdd');
strTime = datestr(now, 'HHMM');



%% Create Section Using Undocumented MATLAB
% Find a reference to the today script document object
tsFile = matlab.desktop.editor.getActive;
[~, tsName, ~] = fileparts(tsFile.Filename);
if ~strcmpi(tsName, strDate)
    tsFile = matlab.desktop.editor.findOpenDocument([strDate '.m']);
end

% Error out if the today script isn't open (probably trying to call this function from the command window)
if isempty(tsFile)
    error('No today script for %s is open. You must create or open this script before creating new sections in it.', strDate);
end

% Replace the new section command with text
newText = sprintf(...
    ['%%%% %s - \n'...
    '%% Today''s parameters\n'...
    'timeStamp = ''%s'';\n'...
    'analysisStamp = '''';\n'...
    'dataSaveName = ''%s/%s - '';\n'...
    '\n'...
    '%% Get references to infraslow BOLD & EEG data sets\n'...
    'boldFiles = get(Paths, ''InfraslowBOLD'');\n'...
    'eegFiles = get(Paths, ''InfraslowBOLD'');'],...
    strTime,...
    [strDate strTime],...
    get(Paths, 'TodayData'),...
    [strDate strTime]);
tsFile.Text = regexprep(tsFile.Text, 'newSection', newText);



%% Create Section Using Low-Level File IO


% % Navigate to the today script folder
% load masterStructs;
% oldDir = pwd;
% cd(fileStruct.Paths.Today);
% 
% % Error out if a file doesn't exist
% if ~exist(strFilename, 'file') || isempty(tsFile)
%     cd(oldDir);
%     error('No today script for %s exists. You must create this script before creating new sections in it.', strDate);
% end
% 
% % Open the file with read/write permissions & get the text inside
% idFile = fopen(strFilename, 'r+');
% text = fread(idFile, '*char')';
% 
% % Read out the index of the new section command & do some error checking
% idxSectionStr = regexp(text, thisFun, 'start') - 1;      % <--- Minus one because offset is zero indexed
% if numel(idxSectionStr) > 1
%     fclose(idFile);
%     cd(oldDir);
%     error('Only one new section may be created at a time');
% elseif isempty(idxSectionStr)
%     fclose(idFile);
%     cd(oldDir);
%     error('The new section function must be run within today''s working script only');
% end
% 
% % Delete the new section command from the file
% fseek(idFile, idxSectionStr, 'bof');
% deleteChar = repmat('\b', 1, length(thisFun));
% 
% % Fill in new section text in the file
% fprintf(idFile, deleteChar);
% fseek(idFile, idxSectionStr, 'bof');
% fprintf(idFile,...
%     [...
%     '%%%% %s - \n'...
%     '%% Today''s parameters\n'...
%     'load masterStructs;\n'...
%     'timeStamp = ''%s'';\n'...
%     'analysisStamp = '],...
%     strTime,...
%     [strDate strTime]);
% 
% % Close the file interface & navigate back to the starting directory
% fclose(idFile);
% cd(oldDir);
