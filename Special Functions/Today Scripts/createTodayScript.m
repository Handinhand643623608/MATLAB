function createTodayScript
%CREATETODAYSCRIPT Creates a new script to serve as a record of daily activities and stores the file
%   in the appropriate folder. It also sets up the date header and the first time-stamped entry
%   section for convenience, then opens the file for you to edit.
%
%   If a script with today's date as the file name already exists in the Today Script folder, then
%   no action is taken and a warning is returned.
%
%   This function takes no input arguments and returns nothing.

%% CHANGELOG
%   Written by Josh Grooms on 20140425
%       20140627:   Added in writing of some initial common parameters under the first time section.
%       20140630:   Added a parameter for naming data files under the first time section.



%% Create the Today-Script
% Navigate to the today-script directory
oldDir = pwd;
cd(get(Paths, 'Today'));

% Get the date of file creation & time of the first entry (right now)
strDate = datestr(now, 'yyyymmdd');
strTime = datestr(now, 'HHMM');
strFilename = [strDate '.m'];

% Create the new script, but don't overwrite any existing files
if exist(strFilename, 'file'); 
    warning('A today-script with today''s date already exists. You''ll have to manually create another one');
else
    idFile = fopen(strFilename, 'w');
    
    % Print the date & time of the first entry in the file
    fprintf(idFile,...
        ['%%%% %s \n'...
         '\n'...
         '\n'...
         '%%%% %s - \n'...
         '%% Today''s parameters\n'...
         'timeStamp = ''%s'';\n'...
         'analysisStamp = \n'...
         'dataSaveName = ''%s/%s - ''\n'...
         '\n'...
         'boldFiles = GetBOLD(Paths);\n'...
         'eegFiles = GetEEG(Paths);\n'],...
        strDate,...
        strTime,...
        [strDate strTime],...
        get(Paths, 'TodayData'),...
        [strDate strTime]);
    
    % Close the low-level editor & open the file in the IDE for user interaction
    fclose(idFile);
    edit(strFilename);
end

% Return to the directory that was scoped before this function was called
cd(oldDir);
    



