classdef Today < hgsetget
% TODAY - A static class containing current date information and Today Script utility functions.    
    
%% CHANGELOG
%   Written by Josh Grooms on 20141015
%       20141022:   Implemented functions for saving Today Script data and images automatically to the appropriate
%                   folder. Implemented current Today Data folder generation inside of the CreateScript method.
%       20141106:   Moved the section creation logic to this class under the new method CreateSection. Filled in
%                   documentation for that method and for CreateScript. Set storage of BrainPlot images to overwrite any
%                   existing files since this can only occur here when Today Script sections are run multiple times,
%                   usually to correct an error or augment a prototype process.
%       20141110:   Implemented some standard assertions to use as this class grows in function. Implemented the ability
%                   to save images to subdirectories of the currently dated Today Data folder.
    


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
        %   This function creates a new today script, which is a script intended to serve as a log of daily research
        %   activities that take place in MATLAB. To this end, it automatically creates a new MATLAB .m script file
        %   inside of the designated log script repository, which is defined by the personalized PATHS dictionary.
        %
        %   Newly created scripts are always named after the date that NTS is invoked on (in YYYYMMDD format) and are
        %   always initialized to contain the very first time-stamped log section. Afterward, if a new section is
        %   desired, the related class method CREATESECTION should be invoked within the script.
        %
        %   INSTRUCTIONS:
        %       1. Once per day (and only once), type "Today.CreateScript()" without quotes into the MATLAB console
        %          window and press the Enter keyboard key. A log file will be created with the current date as its file 
        %          name.
        %           1a. Invoking this method when a file named with the current date already exists is an error.
        %       2. Use "Today.CreateSection()" to create any subsequent time-stamped log sections as desired.
        %
        %   TIP:
        %   Use the shortcut function NTS to avoid having to write out the full class and method name every time a new
        %   daily log script is created.
        %
        %   SYNTAX:
        %       Today.CreateScript()
        %   
        %   See also:   NTS, NTSS, CREATESECTION
            
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
                 '%% Log parameters\n'...
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
        function CreateSection()
        % CREATESECTION - Creates a new log section inside of the current Today Script.
        %   This function creates a new section inside of today's working script that is titled with the time of
        %   creation. It also automatically initializes some commonly used variables at the top of the section for
        %   convenience.
        %
        %   CREATESECTION only works on Today Scripts named with the current date (in YYYYMMDD format). The "current
        %   date" is whatever day the system time evaluates to when CREATESECTION is run. It will not work on scripts
        %   with differently formatted file names or scripts from past dates.
        %   
        %   This function takes no input arguments, returns nothing, and can only be used from within the Today Script
        %   itself.
        %   
        %   INSTRUCTIONS:
        %       1. Open and view the Today Script named with the current date.
        %       2. Click on the empty line in the script where a new log section is to be created.
        %       3. Type this function's name, "Today.CreateSection()" without quotes, on the line.
        %       4. Highlight the function's name, right-click, and select "Evaluate Selection" from the context menu.
        %           4a. The default shortcut for selection evaluation is the F9 keyboard key.
        %
        %   TIP:
        %   Use the shortcut function NTSS to avoid having to write out the full class and method name every time a new 
        %   section is created.
        %
        %   SYNTAX:
        %       Today.CreateSection()
        %
        %   See also:   NTS, NTSS, CREATESCRIPT

            date = Today.Date;
            time = Today.Time;
            
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
                '%% Log parameters\n'...
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
            tsFile.Text = regexprep(tsFile.Text, 'Today.CreateSection(\(\))?|ntss(\(\))?', newText);
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
            
            assert(nargin >= 3, 'A graphics handle, time stamp, and file name must be specified for saving images.');
            Today.SaveImageIn(H, [], timeStamp, fileName, extension);
        end
        function SaveImageIn(H, subFolder, timeStamp, fileName, extension)
        % SAVEIMAGEIN - Saves a time-stamped image to a subdirectory of the current Today Data archive folder.
        %
        %   SYNTAX:
        %       Today.SaveImageIn(H, subFolder, timeStamp, fileName)
        %       Today.SaveImageIn(H, subFolder, timeStamp, fileName, extension)
        %
        %   INPUTS:
        %       H:              INTEGER FIGURE HANDLE
        %                       An integer handle for a valid MATLAB graphics objects whose contents are to be saved as
        %                       an image. This handle can be attained either using the GCF function or by any other
        %                       documented means.
        %
        %       subFolder:      STRING
        %                       A path string indicating a single subdirectory in which to save the inputted graphics
        %                       handle as an image. This path will always be relative to a time-stamped folder created
        %                       in the currently dated Today Data archive. Any number of subdirectory levels may be
        %                       specified. 
        %
        %                       EXAMPLE:
        %                           Today.SaveImageIn(H, 'Child/Directory', '201411101620', 'FileToSave', 'png')
        %
        %                           The command above saves an image of H to the file:
        %                               'X:/Data/Today/20141110/201411101620/Child/Directory/FileToSave.png'
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
            assert(nargin >= 4, 'A sub-folder, graphics handle, time stamp, and file name must be specified for saving images.');
            Today.AssertGraphicsHandle(H);
            Today.AssertDateString(timeStamp);
            Today.AssertFileNameOnly(fileName);
            
            if (nargin == 4); extension = {'fig'}; end
            if (~iscell(extension)); extension = {extension}; end
            
            if (isempty(subFolder)); savePath = Today.Data;
            else savePath = [Today.Data '/' timeStamp '/' subFolder]; end
            saveName = sprintf('%s - %s', timeStamp, fileName);
            
            if (~savePath.Exists); mkdir(savePath); end
            
            if (isa(H, 'BrainPlot'))
                H.Store('Path', savePath.ToString(), 'Name', saveName, 'Ext', extension, 'Overwrite', true);
            else
                saveStr = [savePath.ToString() '/' saveName];
                for a = 1:length(extension)
                    saveas(H, [saveStr '.' extension{a}], extension{a});
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
        %   See also:   DATESTR
            assert(nargin == 1, 'A time stamp must be provided in order to find Today Data files.');
            assert(ischar(timeStamp), 'The time stamp must be provided as a date string.');
            dateStamp = timeStamp(1:8);
            dateFolder = [Paths.TodayData '/' dateStamp];
            assert(dateFolder.Exists, 'Cannot find the Today Data folder from %s. No files can be returned.', dateStamp);
            F = dateFolder.FileSearch(timeStamp);
        end

    end
    
    
    methods (Static, Access = private)
        
        function AssertDateString(timeStamp)
        % ASSERTDATESTRING - Checks for errors in user-inputted time stamp strings.
            assert(ischar(timeStamp), 'Images must be saved with a valid date-time string.');
            assert(length(timeStamp) == 12, 'Date-time strings should be formatted as yyyymmddHHMM.');
        end
        function AssertGraphicsHandle(H)
        % ASSERTGRAPHICSHANDLE - Ensures that a user input is a graphics handle or BrainPlot object.
            assert(ishandle(H) || isa(H, 'BrainPlot'), 'Inputted figure handle must point to an open graphics window.');
        end
        function AssertFileNameOnly(fileName)
        % ASSERTFILENAMEONLY - Ensures that a user input contains only a file name and not a path or an extension.
            [p, f, e] = fileparts(fileName);
            assert(isempty(p), 'File names cannot contain paths or directory specifications.');
            assert(isempty(e), 'File names cannot contain extension specifications.');
            assert(~isempty(f), 'File names must contain a valid name.');
        end
    
    end
    
    
    
end