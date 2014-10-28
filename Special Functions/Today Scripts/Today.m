classdef Today < hgsetget
% TODAY - A static class containing current date information and Today Script utility functions.    
    
%% CHANGELOG
%   Written by Josh Grooms on 20141015
%       20141022:   Implemented functions for saving Today Script data and images automatically to the appropriate
%                   folder. Implemented current Today Data folder generation inside of the CreateScript method.
    


    %% Properties (Defined as Static Methods)
    
    methods (Static)
        
        function P = Data
            % Gets the path to the data folder for the current date.
            P = [Paths.TodayData '/' Today.Date];
        end
        function d = Date
            % Gets the current date string in the format YYYYMMDD.
            d = datestr(now, 'yyyymmdd');
        end
        function t = Time
            % Gets the current time string in the 24-hour format HHMM.
            t = datestr(now, 'HHMM');
        end
        function F = Script
            % Gets the path to the Today Script log file for the current date.
            F = File([Paths.TodayScripts '/' Today.Date '.m']);
        end
        
    end
    
    
    
    
    %% Utility Methods
    
    methods (Static)

        function CreateScript()
        % CREATESCRIPT - Creates and opens a new script to serve as a record of daily activities.
        %
        %   SYNTAX:
        %       Today.CreateScript()
            
            date = Today.Date;
            time = Today.Time;
            script = Today.Script;
            
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
             
             if (~Today.Data.Exists); mkdir(Today.Data); end
        end
        function SaveData(timeStamp, fileName, varargin)
        % SAVEDATA - Saves a time-stamped .MAT file to the current Today Data archive folder.
        %
        %   This method saves a data file to the Today Data repository specified in the PATHS static reference class. It
        %   is intended for use only with daily activity log files (i.e. Today Scripts) and as such offers significantly
        %   reduced functionality compared with the MATLAB-native SAVE function. In exchange, several conveniences
        %   specific to Today Scripts are possible.
        %
        %   To use this function, a minimum of three input arguments must always be supplied. These include a date-time
        %   stamp, the name that the data archive will take once saved, and at least one variable that will be saved
        %   inside the archive. 
        %
        %   Data archives are always '.mat' formatted MATLAB binaries. Specifying different extensions is not an option,
        %   and attempting to do so through the file name itself is an error. Furthermore, archives are always saved to
        %   the present-day Today Data folder, named after the current date in 'yyyymmdd' format. It is not possible to
        %   save archives to a different folder through this function, and attempting to do so is again an error.
        %
        %   SAVING VARIABLES:
        %   Variable saving is handled slightly differently compared to the native SAVE function. In the native version,
        %   the variable name is provided as a string in order to control which workspace variables end up inside the
        %   arhive. Here, however, the variables themselves are inputted as arguments and the names of the variables are
        %   pulled from the calling workspace. 
        %
        %   SYNTAX:
        %       Today.SaveData(timeStamp, fileName, var)
        %       Today.SaveData(timeStamp, fileName, var1, var2,..., varN)
        %
        %   INPUTS:
        %       timeStamp:      STRING
        %                       A string representing the date and time that a particular Today Script section was run.
        %                       This is the time stamp that is automatically generated at the beginning of each
        %                       individual section, and it is recommended that this always be used. The time stamp will
        %                       appear in the saved file at the very beginning of the file name.
        %
        %                       If manually specified, this string should always be formatted as 'yyyymmddHHMM'. Failure
        %                       to do so is an error.
        %
        %       fileName:       STRING
        %                       A string representing the name that the resulting .MAT file will have after the save
        %                       operation. The full file name will consist of the time stamp and this name separated by
        %                       a dash ('-'), followed lastly by the '.mat' extension. This argument must always be a
        %                       string literal; formatting or escape characters will not be processed.
        %
        %       var:            ANYTHING
        %                       At least one variable of any type supported in MATLAB to be saved within the resulting
        %                       .MAT file. Unlike the MATLAB-native SAVE function, this argument must be the variable
        %                       itself, NOT the string name of the variable.
            
            % Error check
            assert(nargin >= 3, 'A time stamp, file name, and at least one variable must be specified for saving data.');
            assert(ischar(timeStamp), 'Data must be saved with a valid date-time string.');
            assert(length(timeStamp) == 12, 'Date-time strings should be formatted as yyyymmddHHMM.');
            [p, fileName, e] = fileparts(fileName);
            assert(isempty(p), 'The directory to which files are saved cannot be specified using this function.');
            assert(isempty(e) || strcmpi(e, '.mat'), 'Only .MAT files can be saved using this function.');
            
            % Get the names of inputted variables from the caller's workspace
            varNames = cell(1, length(varargin));
            for a = 1:length(varargin); varNames{a} = inputname(2 + a); end
            
            % Generate & save a structure containing variables & variable names
            saveStruct = cell2struct(varargin, varNames, 2);
            saveStr = sprintf('%s/%s - %s.mat', Today.Data.ToString(), timeStamp, fileName);
            save(saveStr, '-struct', 'saveStruct', '-v7.3');
        end
        function SaveImage(H, timeStamp, fileName, extension)
        % SAVEIMAGE - Saves a time-stamped image to the current Today Data archive folder.
        %
        %   SYNTAX:
        %       Today.SaveImage(H, timeStamp, fileName)
        %       Today.SaveImage(H, timeStamp, fileName, extension)
        %
        %   INPUTS:
        %       H:              INTEGER FIGURE HANDLE
        %                       An integer handle for a valid MATLAB graphics objects whose contents are to be saved as
        %                       an image. This handle can be attained either using the GCF function or by any other
        %                       documented means. 
        %
        %       timeStamp:      STRING
        %                       A string representing the date and time that a particular Today Script section was run.
        %                       This is the time stamp that is automatically generated at the beginning of each
        %                       individual section, and it is recommended that this always be used. The time stamp will
        %                       appear in the saved file at the very beginning of the file name.
        %
        %                       If manually specified, this string should always be formatted as 'yyyymmddHHMM'. Failure
        %                       to do so is an error.
        %
        %       fileName:       STRING
        %                       A string representing the name that the resulting image file will have after the save
        %                       operation. The full file name will consist of the time stamp and this name separated by
        %                       a dash ('-'), followed lastly by the image extension. This argument must always be a
        %                       string literal; formatting or escape characters will not be processed.
        %
        %   OPTIONAL INPUT:
        %       extension:      STRING or { STRINGS }
        %                       A string or cell array of strings specifying the extension(s) that figure image will
        %                       take once saved. Multiple extensions are supported, including all of those that are
        %                       supported by the MATLAB-native SAVEAS function. Specifying multiple extensions results
        %                       in multiple files with identical names but different formats (e.g. BMP, JPEG, PNG,
        %                       etc.). If omitted, this method saves images as MATLAB .FIG files.
        %                       DEFAULT: 'fig'
            
            % Error check
            assert(nargin >= 3, 'A graphics handle, time stamp, and file name must be specified for saving images.');
            assert(ishandle(H) || isa(H, 'BrainPlot'), 'Inputted figure handle must point to an open graphics window.');
            assert(ischar(timeStamp), 'Images must be saved with a valid date-time string.');
            assert(length(timeStamp) == 12, 'Date-time strings should be formatted as yyyymmddHHMM.');
            [p, fileName, e] = fileparts(fileName);
            assert(isempty(p), 'The directory to which files are saved cannot be specified using this function.');
            
            % Fill in & format the optional extension argument, if needed
            if (nargin == 3)
                if (isempty(e)); extension = {'fig'};
                else extension = e; end
            end 
            if (~iscell(extension)); extension = {extension}; end
            extension = cellfun(@(x) strrep(x, '.', ''), extension, 'UniformOutput', false);
            
            % Save a file for each specified image extension
            if (isa(H, 'BrainPlot'))
                saveStr = sprintf('%s - %s', timeStamp, fileName);
                H.Store('Path', Today.Data.ToString(), 'Name', saveStr, 'Ext', extension);
            else
                saveStr = sprintf('%s/%s - %s.', Today.Data.ToString(), timeStamp, fileName);
                for a = 1:length(extension)
                    saveas(H, [saveStr extension{a}], extension{a});
                end
            end
        end
        
        function F = FindFiles(timeStamp)
        % FINDFILES - Finds files containing a time stamp that were saved to the Today Data repository.
        %
        %   SYNTAX:
        %       F = Today.FindFiles(timeStamp)
        %
        %   OUTPUT:
        %       F:          FILE or [ FILES ]
        %                   A File object or array of objects that reference files found inside of the Today Script data
        %                   respository for the date indicated by the time stamp argument. These files must have been
        %                   saved with a time stamp that is identical to the one inputted here in order to be found.
        %
        %   INPUT:
        %       timeStamp:  STRING
        %                   A date-time string used to identify a specific set of files located in the Today Script data
        %                   repository. This string must be formatted as "yyyymmddHHMM". The date part of this string
        %                   (i.e. the first 8 characters) is used to identify which folder the files are located in,
        %                   while the whole string is used to find the files themselves.
        %                   EXAMPLE:
        %                       
        %                       "201410281045" - Finds files containing a time stamp of 10:45 AM on October 28th, 2014.
        %
        %                       
        %
        %   See also:   DATESTR
            assert(nargin == 1, 'A time stamp must be provided in order to find Today Data files.');
            assert(ischar(timeStamp), 'The time stamp must be provided as a date string.');
            dateStamp = timeStamp(1:8);
            dateFolder = [Paths.TodayData '/' dateStamp];
            assert(dateFolder.Exists, 'Cannot find the Today Data folder from %s. No files can be returned.', dateStamp);
            F = dateFolder.FileSearch(timeStamp);
        end

    end
    
    
    
    
    
    
    
    
end