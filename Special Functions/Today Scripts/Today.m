classdef Today < hgsetget
% TODAY - A static class containing current date information and Today Script utility functions.    
    
%% CHANGELOG
%   Written by Josh Grooms on 20141015
    


    %% Properties (Defined as Static Methods)
    
    methods (Static)
        
        function P = Data
            % Gets the path to the data folder for the current date.
            P = [Paths.TodayData '/' Today.Date];
        end
        function D = Date
            % Gets the current date string in the format YYYYMMDD.
            D = datestr(now, 'yyyymmdd');
        end
        function T = Time
            % Gets the current time string in the 24-hour format HHMM.
            T = datestr(now, 'HHMM');
        end
        function P = ScriptPath
            % Gets the path to the folder containing Today Scripts.
            P = Paths.TodayScripts;
        end
        
        
    end
    
    
    
    
    %% Utility Methods
    
    methods (Static)

        function CreateScript()
        % CREATESCRIPT - Creates a new script to serve as a record of daily activities.
            
            date = Today.Date;
            time = Today.Time;
            script = File([Paths.TodayScripts '/' date '.m']);
            
            assert(~script.Exists, 'A Today Script with today''s date already exists.');
            
            script.Open('w');
            script.Write(...
                ['%%%% %s \n'...
                 '\n'...
                 '\n'...
                 '%%%% %s - \n'...
                 '%% Today''s parameters\n'...
                 'timeStamp = ''%s'';\n'...
                 'analysisStamp = '''';\n'...
                 'dataSaveName = ''%s/%s - '';\n'...
                 '\n'...
                 '%% Get references to infraslow BOLD & EEG data sets\n'...
                 'boldFiles = Files.BOLD;\n'...
                 'eegFiles = Files.EEG;\n'],...
                 date,...
                 time,...
                 [date time],...
                 Today.Data.ToString(),...
                 [date time]);
            
             script.Close();
             script.Edit();
        end
        function F = FindFiles(timeStamp)
        % FINDFILES - Finds files containing a time stamp that were saved to the Today Data repository.
            assert(nargin == 1, 'A time stamp must be provided in order to find Today Data files.');
            assert(ischar(timeStamp), 'The time stamp must be provided as a date string.');
            dateStamp = timeStamp(1:8);
            dateFolder = [Paths.TodayData '/' dateStamp];
            assert(dateFolder.Exists, 'Cannot find the Today Data folder from %s. No files can be returned.', dateStamp);
            F = dateFolder.FileSearch(timeStamp);
        end

    end
    
    
    
    
    
end