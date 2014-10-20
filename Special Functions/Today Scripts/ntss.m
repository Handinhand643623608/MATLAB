function ntss
% NTSS - Creates a New Today Script Section inside of the current today script.
%   This function creates a new section inside of today's working script that is titled with the time of creation. It
%   also automatically initializes some commonly used variables at the top of the section for convenience.
%
%   NTSS only works on Today Scripts named with the current date (in YYYYMMDD format). The "current date" is
%   whatever day the system time evaluates to when NTSS is run. It will not work on scripts with differently
%   formatted file names or scripts from past dates.
%   
%   This function takes no input arguments, returns nothing, and can only be used from within the Today Script itself.
%   
%   INSTRUCTIONS:
%       1. Open and view the Today Script named with the current date.
%       2. Click on the empty line in the script where a new time section is to be created.
%       3. Type this function's name, "ntss" without quotes, on the line.
%       4. Highlight the function's name, right-click, and select "Evaluate Selection" from the context menu.
%           4a. The default shortcut for selection evaluation is the F9 keyboard key.

%% CHANGELOG
%   Written by Josh Grooms on 20140627
%       20140630:   Added a parameter for naming data files under the first time section.
%       20141008:   Updated for compatibility with changed infraslow data dependent properties of the Paths object.
%                   Added an automatic comment placement for retrieving data file references. Added semicolons to the
%                   ends of variables listed at the beginning of the section. Made the analysis stamp an empty string
%                   instead of an incomplete line of code.
%       20141016:   Renamed this function from "newSection" to "ntss" to facilitate easier entry of the command in Today
%                   Scripts. Updated to work with the new Today class.



%% Create a New Today-Script Section
% Initialize important file name & time strings
date = Today.Date;
time = Today.Time;



%% Create Section Using Undocumented MATLAB
% Find a reference to the today script document object
tsFile = matlab.desktop.editor.getActive;
[~, tsName, ~] = fileparts(tsFile.Filename);
if ~strcmpi(tsName, date)
    tsFile = matlab.desktop.editor.findOpenDocument([date '.m']);
end

% Error out if the today script isn't open (probably trying to call this function from the command window)
assert(~isempty(tsFile), 'No today script for %s is open. You must create and open this script before creating new sections in it.', date); 

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
    time,...
    [date time],...
    Today.Data.ToString(),...
    [date time]);
tsFile.Text = regexprep(tsFile.Text, 'ntss', newText);

