% TODAY - A static class containing current date information and Today Script utility functions.
%
%	Today Properties:
%		Data				- Gets the Path to the data folder for the current date.
%		Date				- Gets the current date as a string.
%		Time				- Gets the current time in 24-hour format as a string.
%		Script				- Gets a File object referencing the log script for the current date.
%		
%	Today Methods:
%		Archive				- Copies research data from its original storage location to a local archive folder.
%		CreateScript		- Creates and opens a new script to serve as a record of daily research activities.
%		CreateSection		- Creates a new time-stamped log section inside of the current Today Script.
%		CreateSubsection	- Creates a subsection inside of a Today Script delineated by a commented line of '=' characters.
%		FindFiles			- Finds files containing a specified time stamp that were saved to the Today Data repository.
%		FindLogs			- Finds log script files using a specified time stamp.
%		LoadGlobals			- Executes any code written in the very first section of the script in which it is called.
%		Outline				- Displays an outline of Today Script section headers in the console window.
%		SaveData			- Saves a time-stamped .MAT file to the current Today Data repository.
%		SaveImage			- Saves a time-stamped image to the current Today Data repository.
%		SaveImageIn			- Saves a time-stamped image to a subdirectory within the current Today Data repository.
%		SearchLogs			- Searches through the section header text of all Today Scripts for a specified string.
    
%% CHANGELOG
%   Written by Josh Grooms on 20141015
%       20141022:   Implemented functions for saving Today Script data and images automatically to the appropriate folder. 
%					Implemented current Today Data folder generation inside of the CreateScript method.
%       20141106:   Moved the section creation logic to this class under the new method CreateSection. Filled in
%                   documentation for that method and for CreateScript. Set storage of BrainPlot images to overwrite any
%                   existing files since this can only occur here when Today Script sections are run multiple times, usually
%                   to correct an error or augment a prototype process.
%       20141110:   Implemented some standard assertions to use as this class grows in function. Implemented the ability to 
%					save images to subdirectories of the currently dated Today Data folder.
%		20141118:	Made a new private method SectionText for creating script section text so that it's easier to modify
%					in the future if needed. Updated CreateScript and CreateSection methods to utilize it. Also removed the
%					dataSaveName variable from this text since it's not really used anymore.
%		20141120:	Bug fix for first section creation not being done properly when new Today Scripts are created.
%		20141210:	Implemented a method for archiving Today Data.
%		20141212:	Implemented a method for automatically loading global variables stored at the very beginning of a Today 
%					Script research log. Implemented static fields containing the desired formatting of date, time, and 
%					date-time strings in case these need to be changed in the future. Added some standard assertions for 
%					date- and time-related strings. Added in an automatic placement of the global variable loading method at 
%					the beginning of the text for each section. Removed the automatic placement of infraslow data set 
%					references from each section. These aren't used nearly as often as I initially thought they would be.
%		20141217:	Implemented methods for finding open MATLAB documents (e.g. scripts and functions) and for replacing
%					text inside of them. Replaced the relevant section of CreateSection with these new functions. Also
%					implemented a new method CreateSubsection for creating comment line separators within log scripts.
%       20150129:   Implemented the automatic searching of data archives in the method FindFiles when data with the inputted
%                   time stamp can't be found on my work flash drive.
%       20150202:   Changed the behavior of CreateScript so that it opens a pre-existing log file instead of erroring out.
%		20150224:	Implemented methods to outline and search the section header text of log files.
%		20150507:	Overhauled the class documentation to summarize all of the properties and methods that are available.
%		20150511:	Updated for compatibility with changes to file management objects.



%% CLASS DEFINITION
classdef Today

    


    %% PROPERTIES
    
    methods (Static)
        function P = Data
        % Gets the path to the data folder for the current date.
            P = [Paths.TodayData '/' Today.Date];
        end
        function d = Date
        % Gets the current date string in the format YYYYMMDD.
            d = datestr(now, Today.DateFormat);
        end
        function t = Time
        % Gets the current time string in the 24-hour format HHMM.
            t = datestr(now, Today.TimeFormat);
        end
        function F = Script
        % Gets the path to the Today Script log file for the current date.
			date = Today.Date;
            F = [Paths.TodayScripts '/' date(1:4) '/' date(5:6) '/' date '.m'];
		end
	end
	
	methods (Static, Access = private)
		
		function f = DateFormat
		% Gets the format of date strings.
			f = 'yyyymmdd';
		end
		function f = DateTimeFormat
		% Gets the format of date-time strings.
			f = 'yyyymmddHHMM';
		end
		function f = TimeFormat
		% Gets the standard format of time strings.	
			f = 'HHMM';
		end
		
	end
    
    
    
    %% UTILITIES
    
    methods (Static)

		function Archive()
		% ARCHIVE - Performs a simple copy of new Today Data to the locally stored archive.
		%
		%	ARCHIVE copies data stored in the portable Today Data repository (i.e. my flash drive) to a local archive whose
		%	location depends on the computer being worked on.
		%
		%	SYNTAX:
		%		Today.Archive()
			
			% Get the portable & archive folder contents
			pc = Paths.TodayData.Contents();
			pdirs = {pc.Name}';
			ac = Paths.TodayArchive.Contents();
			adirs = {ac.Name}';
			
			% Determine which of the portable folders is new, compared to the archive contents
			idsNewFolders = ~ismember(pdirs, adirs);
			dirsToCopy = pc(idsNewFolders);
			
			% Copy the new folders
			wasCopied = dirsToCopy.CopyTo(Paths.TodayArchive);
			
			% Warn of any uncopied data in the MATLAB console
			if any(~wasCopied)
				idsNotCopied = find(~wasCopied);
				fprintf('The following directories could not be automatically copied to the data archive:\n\n');
				for a = 1:length(idsNotCopied)
					fprintf('\t%s\n', dirsToCopy(a).Name);
				end
			end
		end
        function CreateScript()
        % CREATESCRIPT - Creates and opens a new script to serve as a record of daily activities.
		%	
        %   This function creates a new today script, which is a script intended to serve as a log of daily research
        %   activities that take place in MATLAB. To this end, it automatically creates a new MATLAB .m script file inside of
        %   the designated log script repository, which is defined by the personalized PATHS dictionary.
        %
        %   Newly created scripts are always named after the date that NTS is invoked on (in YYYYMMDD format) and are always
        %   initialized to contain the very first time-stamped log section. Afterward, if a new section is desired, the
        %   related class method CREATESECTION should be invoked within the script.
        %
        %   INSTRUCTIONS:
        %       1.	Once per day (and only once), type "Today.CreateScript()" without quotes into the MATLAB console window 
		%			and press the Enter keyboard key. A log file will be created with the current date as its file name.
        %       2. Use "Today.CreateSection()" to create any subsequent time-stamped log sections as desired.
        %
        %   TIP:
        %		Use the shortcut function NTS to avoid having to write out the full class and method name every time a new
        %		daily log script is created.
        %
        %   SYNTAX:
        %       Today.CreateScript()
        %   
        %   See also:   NTS, NTSS, NTSSS, TODAY.CREATESECTION
            
            date = Today.Date;
            script = Today.Script;
            
            if (script.Exists); script.Edit(); return; end
			if (~script.ParentDirectory.Exists); mkdir(script.ParentDirectory); end
			
            script.Open('w');
			script.Write('%%%% %s\n\n\n\nntss', date);
            script.Close();
            script.Edit();
            
			Today.CreateSection();
			
            if (~Today.Data.Exists); mkdir(Today.Data); end
        end
        function CreateSection()
        % CREATESECTION - Creates a new log section inside of the current Today Script.
        %
		%   This function creates a new section inside of today's working script that is titled with the time of creation. It
        %   also automatically initializes some commonly used variables at the top of the section for convenience.
        %
        %   CREATESECTION only works on Today Scripts named with the current date (in YYYYMMDD format). The "current date" is
        %   whatever day the system time evaluates to when CREATESECTION is run. It will not work on scripts with differently
        %   formatted file names or scripts from past dates.
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
        %		Use the shortcut function NTSS to avoid having to write out the full class and method name every time a new 
        %		section is created.
        %
        %   SYNTAX:
        %       Today.CreateSection()
        %
        %   See also:   NTS, NTSS, TODAY.CREATESCRIPT
            date = Today.Date;
            time = Today.Time;
			newText = Today.SectionText(date, time);
			Today.ReplaceTextInOpenDoc([date '.m'], 'Today.CreateSection(\(\))?|ntss(\(\))?', newText);
		end
		function CreateSubsection()
		% CREATESUBSECTION - Creates a new log subsection delineated by a comment line filled with '=' characters.
			Today.ReplaceTextInOpenDoc([Today.Date '.m'], 'Today.CreateSubsection(\(\))?|ntsss(\(\))?',...
				['%' repmat('=', 1, 124)]);
		end
		function LoadGlobals(date)
		% LOADGLOBALS - Executes global variables and code written in the very first section of a Today Script.
		%
		%	LOADGLOBALS evaluates the first section of a Today Script (i.e. the very first section that starts with the date
		%	of the script and ends with the first time-stamped section). This section is intended to hold variables that are
		%	globally applicable throughout every or at least most sections of the script.
		%
		%	SYNTAX:
		%		Today.LoadGlobals(date)
		%
		%	INPUT:
		%		date:		STRING
		%					A string containing the date of script from which the call to this method is being made. This
		%					date string must be in the format 'yyyymmdd'.
		%
		%	See also: TODAY.CREATESCRIPT, TODAY.CREATESECTION, TODAY.CREATESUBSECTION
			
			Today.AssertDateString(date);
			
			tsFile = matlab.desktop.editor.getActive;
			[~, tsName, ~] = fileparts(tsFile.Filename);
			if ~strcmpi(tsName, date)
                tsFile = matlab.desktop.editor.findOpenDocument([date '.m']);	
			end
			
			% Error out if the today script isn't open (probably trying to call this function from the command window)
            assert(~isempty(tsFile),...
				'No today script for %s is open. You must create or open this script before loading global variables in it.', date); 
			
			% Find any code written in the very first section of the script
			allText = tsFile.Text;
			idxGV = regexp(allText, '%% \d{4} - ', 'once');
			
			% Execute the code in the base workspace
			if ~isempty(idxGV)
				gvSection = allText(1:idxGV);
				evalin('base', gvSection);
			end
		end
		function Outline(timeStamp)
		% OUTLINE - Displays an outline of the section headers from one or more Today Script log files.
		%
		%	This method displays an outline of one or more Today Script log files using the sections headers from within.
		%	Section headers are characterized by the presence of '%%' at the beginning of a line in a .m file and are
		%	typically created by the TODAY.CREATESECTION method. 
		%
		%	The outline is displayed within the MATLAB console window and is formatted by file and time stamp for each of a
		%	file's sections. Both the file name and each section time stamp are hyperlinked to the appropriate region of the
		%	original log file. Thus, clicking a link opens the file and allows for quick access to the code that was used as
		%	well as any additional comments that were made at that time.
		%
		%	SYNTAX:
		%		Today.Outline()
		%		Today.Outline(timeStamp)
		%
		%	OPTIONAL INPUT:
		%		timeStamp:		STRING
		%						A date string that is used to identify the files being outlined. Unlike the time stamp
		%						arguments used in other Today Script methods, the formatting of this parameter is somewhat
		%						flexible. Specifically, this time stamp can be a year ('YYYY'), a year and a month
		%						('YYYYMM'), or a full date string ('YYYYMMDD'). When the first two options are used, all
		%						files associated with the dates are outlined. Using '2015', for example, would result in an
		%						outline of every file from that year. By default, every available log file is outlined.
		%
		%	See also: TODAY.FINDLOGS, TODAY.SEARCHLOGS
	
			if (nargin == 0)
				F = Paths.TodayScripts.AllFiles();
			else
				F = Today.FindLogs(timeStamp);
			end
			[s, l] = Today.GetSectionHeaderText(F);
			Today.DisplayOutline(F, s, l);
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
			Today.AssertDateTimeString(timeStamp);
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
        %                       An integer handle for a valid MATLAB graphics objects whose contents are to be saved as an
        %                       image. This handle can be attained either using the GCF function or by any other documented
        %                       means.
        %
        %       timeStamp:      STRING
        %                       A string representing the date and time that a particular Today Script section was run. This
        %                       is the time stamp that is automatically generated at the beginning of each individual
        %                       section, and it is recommended that this always be used. The time stamp will appear in the
        %                       saved file at the very beginning of the file name.
        %
        %                       If manually specified, this string should always be formatted as 'yyyymmddHHMM'. Failure to
        %                       do so is an error.
        %
        %       fileName:       STRING
        %                       A string representing the name that the resulting image file will have after the save
        %                       operation. The full file name will consist of the time stamp and this name separated by a
        %                       dash ('-'), followed lastly by the image extension. This argument must always be a string
        %                       literal; formatting or escape characters will not be processed.
        %
        %   OPTIONAL INPUT:
        %       extension:      STRING or { STRINGS }
        %                       A string or cell array of strings specifying the extension(s) that figure image will take
        %                       once saved. Multiple extensions are supported, including all of those that are supported by
        %                       the MATLAB-native SAVEAS function. Specifying multiple extensions results in multiple files
        %                       with identical names but different formats (e.g. BMP, JPEG, PNG, etc.). If omitted, this
        %                       method saves images as MATLAB .FIG files.
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
        %                       An integer handle for a valid MATLAB graphics objects whose contents are to be saved as an
        %                       image. This handle can be attained either using the GCF function or by any other documented
        %                       means.
        %
        %       subFolder:      STRING
        %                       A path string indicating a single subdirectory in which to save the inputted graphics handle
        %                       as an image. This path will always be relative to a time-stamped folder created in the
        %                       currently dated Today Data archive. Any number of subdirectory levels may be specified.
        %
        %                       EXAMPLE:
        %                           Today.SaveImageIn(H, 'Child/Directory', '201411101620', 'FileToSave', 'png')
        %
        %                           The command above saves an image of H to the file:
        %                               'X:/Data/Today/20141110/201411101620/Child/Directory/FileToSave.png'
        %
        %       timeStamp:      STRING
        %                       A string representing the date and time that a particular Today Script section was run. This
        %                       is the time stamp that is automatically generated at the beginning of each individual
        %                       section, and it is recommended that this always be used. The time stamp will appear in the
        %                       saved file at the very beginning of the file name.
        %
        %                       If manually specified, this string should always be formatted as 'yyyymmddHHMM'. Failure to
        %                       do so is an error.
        %
        %       fileName:       STRING
        %                       A string representing the name that the resulting image file will have after the save
        %                       operation. The full file name will consist of the time stamp and this name separated by a
        %                       dash ('-'), followed lastly by the image extension. This argument must always be a string
        %                       literal; formatting or escape characters will not be processed.
        %
        %   OPTIONAL INPUT:
        %       extension:      STRING or { STRINGS }
        %                       A string or cell array of strings specifying the extension(s) that figure image will take
        %                       once saved. Multiple extensions are supported, including all of those that are supported by
        %                       the MATLAB-native SAVEAS function. Specifying multiple extensions results in multiple files
        %                       with identical names but different formats (e.g. BMP, JPEG, PNG, etc.). If omitted, this
        %                       method saves images as MATLAB .FIG files. 
		%						DEFAULT: 'fig'
		%
		%	See also: TODAY.FINDFILES, TODAY.SAVEDATA, TODAY.SAVEIMAGE
            assert(nargin >= 4, 'A sub-folder, graphics handle, time stamp, and file name must be specified for saving images.');
            Today.AssertGraphicsHandle(H);
            Today.AssertDateTimeString(timeStamp);
            Today.AssertFileNameOnly(fileName);
            
            if (nargin == 4); extension = {'fig'}; end
            if (~iscell(extension)); extension = {extension}; end
            
            if (isempty(subFolder)); savePath = Today.Data;
            else savePath = [Today.Data '/' timeStamp '/' subFolder]; end
            saveName = sprintf('%s - %s', timeStamp, fileName);
            
            if (~savePath.Exists); mkdir(savePath); end
            
            if (isa(H, 'Window')); H = H.ToFigure(); end
			saveStr = [savePath.ToString() '/' saveName];
			for a = 1:length(extension)
				saveas(H, [saveStr '.' extension{a}], extension{a});
			end
		end
        function SearchLogs(query)
		% SEARCHLOGS - Searches the section header text of Today Script log files.
		%
		%	This method searches all available Today Script log files and their section headers for text matching the
		%	inputted query string. Any matches are then displayed in outline form within the MATLAB console window. Section
		%	headers are characterized by the presence of '%%' at the beginning of a .m file line and are typically created by
		%	the TODAY.CREATESECTION method. 
		%	
		%	SYNTAX:
		%		Today.SearchLogs(query)
		%
		%	INPUT:
		%		query:		STRING
		%					A query string that will be searched for within the section header text of all available log
		%					script files. Searching is performed using regular expressions, and so this argument may contain
		%					metacharacters. It is also case-insensitive.
		%
		%	See also: TODAY.FINDLOGS, TODAY.OUTLINE
			F = Paths.TodayScripts.FileContents(true);
			[s, l] = Today.GetSectionHeaderText(F);
			
			for a = 1:numel(F)
				ids = cellfun(@isempty, regexpi(s{a}, query));
				s{a}(ids) = [];
				l{a}(ids) = [];
			end			
			
			ids = cellfun(@isempty, s);
			F(ids) = [];
			s(ids) = [];
			l(ids) = [];
			
			Today.DisplayOutline(F, s, l);
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
        %                   respository for the date indicated by the time stamp argument. These files must have been saved
        %                   with a time stamp that is identical to the one inputted here in order to be found.
        %
        %   INPUT:
        %       timeStamp:  STRING
        %                   A date-time string used to identify a specific set of files located in the Today Script data
        %                   repository. This string must be formatted as "yyyymmddHHMM". The date part of this string (i.e.
        %                   the first 8 characters) is used to identify which folder the files are located in, while the
        %                   whole string is used to find the files themselves.
        %                   EXAMPLE:
        %                       
        %                       "201410281045" - Finds files containing a time stamp of 10:45 AM on October 28th, 2014.
        %
        %   See also:   DATESTR, TODAY.FINDLOGS
            
            assert(nargin == 1, 'A time stamp must be provided in order to find Today Data files.');
            Today.AssertDateTimeString(timeStamp);
            dateStamp = timeStamp(1:8);
            dateFolder = [Paths.TodayData '/' dateStamp];
            
            if ~(dateFolder.Exists)
                dateFolder = [Paths.TodayArchive '/' dateStamp];
                assert(dateFolder.Exists, 'Cannot find the Today Data folder from %s. No files can be returned.', dateStamp);
            end
            
            F = dateFolder.FileSearch(timeStamp);
            
            if isempty(F)
                dateFolder = [Paths.TodayArchive '/' dateStamp];
                F = dateFolder.FileSearch(timeStamp);
            end
		end
		function F = FindLogs(timeStamp)
		% FINDLOGS - Finds log script files using a time stamp.
		%
		%	SYNTAX:
		%		F = Today.FindLogs(timeStamp)
		%
		%	OUTPUT:
		%		F:				[ FILES ]
		%						An array of file objects referencing Today Script log files whose names match the time stamp
		%						query string.
		%	INPUT:
		%		timeStamp:		STRING
		%						A date string that is used to identify the log files. Unlike the time stamp arguments used in
		%						other Today Script methods, the formatting of this parameter is somewhat flexible.
		%						Specifically, this time stamp can be a year ('YYYY'), a year and a month ('YYYYMM'), or a
		%						full date string ('YYYYMMDD').
		%
		%	See also: FILE
			
			assert(length(timeStamp) >= 4, 'Invalid time stamp.');
			switch length(timeStamp)
				case 4
					F = FileContents([Paths.TodayScripts '/' timeStamp], true);
				case 6
					F = FileContents([Paths.TodayScripts '/' timeStamp(1:4) '/' timeStamp(5:6)]);
				case 8
					F = [Paths.TodayScripts '/' timeStamp(1:4) '/' timeStamp(5:6) '/' timeStamp '.m'];
				otherwise
					error('Invalid time stamp detected.');
			end
		end
		
    end
    
    
    methods (Static, Access = private)
        
		function AssertDateString(t)
		% ASSERTDATESTRING - Checks for errors in user-inputted date stamp strings.
			f = Today.DateFormat;
			assert(ischar(t), 'Dates must be provided as string-type variables.');
			assert(length(t) == length(f), 'Dates must be provided in the format %s.', f);
		end
        function AssertDateTimeString(t)
        % ASSERTDATETIMESTRING - Checks for errors in user-inputted date-time stamp strings.
			f = Today.DateTimeFormat;
            assert(ischar(t), 'Date-time strings must be provided as string-type variables.');
            assert(length(t) == length(f), 'Date-time strings must be provided in the format %s.', f);
        end
        function AssertGraphicsHandle(H)
        % ASSERTGRAPHICSHANDLE - Ensures that a user input is a graphics handle or a window object.
            assert(ishandle(H) || isa(H, 'Window'), 'Inputted figure handle must point to an open graphics window.');
        end
        function AssertFileNameOnly(fileName)
        % ASSERTFILENAMEONLY - Ensures that a user input contains only a file name and not a path or an extension.
            [p, f, e] = fileparts(fileName);
            assert(isempty(p), 'File names cannot contain paths or directory specifications.');
            assert(isempty(e), 'File names cannot contain extension specifications.');
            assert(~isempty(f), 'File names must contain a valid name.');
		end
		
		function DisplayOutline(F, s, l)
		% DISPLAYOUTLINE - Displays a formatted outline of log script section headers with hyperlinked time stamps.
		%
		%	INPUTS:
		%		F:		FILE or [ FILES ]
		%				The files from which the headers in S were read.
		%
		%		s:		{ 1 x N { STRINGS } }
		%				A cell array of section header text collections. The number of cells in the outer-most layer (N) must
		%				match the number of files in F.
		%
		%		l:		{ 1 x N [ INTEGERS ] }
		%				The line numbers that correspond with the strings in S.
			for a = 1:numel(F)
				fprintf(1, '\n\t<a href="matlab: opentoline(''%s'',%d)">%s</a>\n',...
					F(a).FullPath,...
					1,...
					F(a).Name);
				
				for b = 1:length(s{a})
					if (~isempty(s{a}{b}) && l{a}(b) ~= 1)
						fprintf(1, '\t\t<a href="matlab: opentoline(''%s'',%d)">%s</a>%s\n',...
							F(a).FullPath,...
							l{a}(b),...
							s{a}{b}(1:4),...
							s{a}{b}(5:end));
					end
				end
			end
			
			fprintf(1, '\n');
		end
		function ReplaceTextInOpenDoc(fileName, oldText, newText)
		% REPLACETEXTINOPENDOC - Finds and replaces text in a currently open script or function file.
			assert(ischar(fileName) && ischar(oldText) && ischar(newText),...
				'All input arguments must be specified as string type variables.');
			D = Today.FindOpenDocument(fileName);
			assert(~isempty(D), 'Could not find an open document named %s. Text replacement is not possible.', fileName);
			D.Text = regexprep(D.Text, oldText, newText);
		end
		
		function D = FindOpenDocument(fileName)
		% FINDOPENDOCUMENT - Finds and returns a DOCUMENT object referencing a currently open script or function file.
			assert(ischar(fileName), 'File names must be specified as string type arguments.');
			ext = File.GetExtension(fileName);
			if ~strcmpi(ext, '.m'); fileName = [fileName '.m']; end
			D = matlab.desktop.editor.findOpenDocument(fileName);
		end
		function [s, l] = GetSectionHeaderText(F)
		% GETSECTIONHEADERTEXT - Compiles a list of log script section header text from the inputted files.
		%
		%	OUTPUTS:
		%		s:		{ 1 x N { STRINGS } }
		%				A cell array of cell arrays containing section header text. The number of cells in the outer-most
		%				layer corresponds with the number of file references that were provided. Each of the outer cells
		%				contains all section headers from one individual file.
		%
		%		l:		{ 1 x N [ INTEGERS ] }
		%				The line number on which the corresponding strings in S can be found in the original log file. This
		%				is formatted identically to S.
		%
		%	INPUT:
		%		F:		FILE or [ FILES ]
		%				A file or array of file references from which section headers will be grabbed. The total number of
		%				files here dictates the number of cells in the outer-most layer of S and L. 
			s = cell(size(F));
			l = cell(size(F));
			
			for a = 1:numel(F)
				txt = strsplit(F(a).ReadAllText(), '\n', 'CollapseDelimiters', false)';
				txt = regexpi(txt, '%%\s*([^\r\n]*)', 'tokens');
				ids = find(~cellfun(@isempty, txt));
				l{a} = cat(1, l{a}, ids);
				s{a} = cat(1, s{a}, txt{ids});
				s{a} = [s{a}{:}]';
			end
		end
		function s = SectionText(date, time)
		% SECTIONTEXT - Gets the standard text to be automatically placed in each script section.
			s = sprintf(...
				['%%%% %s - \n'...
                 '%% Log parameters\n'...
				 'Today.LoadGlobals(''%s'');\n',...
                 'timeStamp = ''%s'';\n'...
                 'analysisStamp = '''';\n'],...
                 time,...
				 date,...
                 [date time]);
		end
    
    end
    
    
    
end