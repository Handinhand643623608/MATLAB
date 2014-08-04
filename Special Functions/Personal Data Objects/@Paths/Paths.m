classdef Paths < hgsetget
%PATHS - A class for managing and storing important personal computer paths.
%
%   SYNTAX:
%   myPaths = Paths
%
%   OUTPUT:
%   myPaths:        PATHS
%                   A data object containing paths to several frequently used directories. The returned paths are
%                   environment sensitive; an unlimited number of alternative path lists can be specified for every
%                   computer whose name is known. The appropriate path sets are selected automatically.

%% CHANGELOG
%   Written by Josh Grooms on 20140630
%       20140702:   Added a property to contain a path to a frequently used flash drive. Implemented a method for
%                   retrieving all folder contents (subfolders included). Implemented a method for converting objects
%                   into structures. Implemented a get method for the TodayData folder that points to a folder named
%                   after the current date, creating the folder if it doesn't exist.
%       20140718:   Added in some paths for my new CABI account.
   
    
    %% Important Paths
    properties
       
        BOLD                % The path to all BOLD data objects.
        DataObjects         % The path to all data objects.
        Desktop             % The path to the computer's desktop.
        EEG                 % The path to all EEG data objects.
        FlashDrive          % The path to a USB flash drive.
        Globals             % The path to all global functions.
        Main                % The path to the main coding workspace.
        Raw                 % The path to all raw BOLD and EEG data sets.
        Today               % The path to all today scripts.
        TodayData           % The path to where all today script data sets are saved.
        
    end
    
    
    %% Constructor Method
    methods
        function myPaths = Paths
            %PATHS - Constructs a personalized path storage object for frequently used computer folders.
            computerName = getenv('COMPUTERNAME');
            switch lower(computerName)
                case 'desktop'
                    myPaths.DataObjects   = 'E:/Graduate Studies/Lab Work/Data Sets/Data Objects';
                    myPaths.Desktop       = 'C:/Users/Josh/Desktop';
                    myPaths.Globals       = 'C:/Users/Josh/Dropbox/Globals';
                    myPaths.Main          = 'C:/Users/Josh/Dropbox/svnSandbox';
                    myPaths.Raw           = 'E:/Graduate Studies/Lab Work/Data Sets/Raw Data';
                    myPaths.Today         = 'C:/Users/Josh/Dropbox/svnSandbox/Today Scripts';
                    myPaths.TodayData     = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data';
                    
                case 'shella-bigboy1'
                    myPaths.DataObjects   = 'C:/Users/jgrooms/Desktop/Data Sets/Data Objects';
                    myPaths.Desktop       = 'C:/Users/jgrooms/Desktop';
                    myPaths.FlashDrive    = 'E:';
                    myPaths.Globals       = 'C:/Users/jgrooms/Dropbox/Globals';
                    myPaths.Main          = 'C:/Users/jgrooms/Dropbox/svnSandbox';
                    myPaths.Raw           = 'S:/Josh/Data/Raw';
                    myPaths.Today         = 'C:/Users/jgrooms/Dropbox/svnSandbox/Today Scripts';
                    myPaths.TodayData     = 'C:/Users/jgrooms/Desktop/Today Data';
                    
                case ''     % CABI doesn't have names evidently...
                    myPaths.DataObjects   = '';
                    myPaths.Desktop = '/home/jgrooms/Desktop';
                    myPaths.FlashDrive = '';
                    myPaths.Globals = '/home/jgrooms/Dropbox/Globals';
                    myPaths.Main = '/home/jgrooms/Dropbox/svnSandbox';
                    myPaths.Raw = '';
                    myPaths.Today = '/home/jgrooms/Dropbox/svnSandbox/Today Scripts';
                    myPaths.TodayData = '/home/jgrooms/Desktop/Today Data';
            end
            
            % Fill in paths that can be derived
            myPaths.BOLD = [myPaths.DataObjects '/BOLD'];
            myPaths.EEG = [myPaths.DataObjects '/EEG'];
        end
    end
    
    
    
    %% Data File Retrieval & Query Methods
    methods
        % Get a list of paths to all folder contents
        pathList = Contents(myPaths, folder)
        % Search through a folder for specific files
        pathList = Search(myPaths, folder, searchStr, varargin)
    end
    
    
    
    %% Shortcut Methods
    methods
        % Shortcut method for changing the working directory
        function CD(myPaths, folder)
            %CD - Quickly change the MATLAB working directory to a folder in the PATHS object.
            cd(get(myPaths, folder));
        end
        % Shortcut method for getting current BOLD data object paths (infraslow data)
        function pathList = GetBOLD(myPaths, searchStr)
            %GETBOLD - Returns a list of paths to all current infraslow BOLD data objects.
            if nargin == 1; searchStr = []; end
            pathList = Search(myPaths, 'BOLD', ['boldObject.*' searchStr '.*'], 'Ext', '.mat'); 
        end
        % Shortcut method for getting current EEG data object paths (infraslow data)
        function pathList = GetEEG(myPaths, searchStr)
            %GETEEG - Returns a list of paths to all current infraslow EEG data objects.
            if nargin == 1; searchStr = []; end
            pathList = Search(myPaths, 'EEG', ['eegObject.*' searchStr '.*'], 'Ext', '.mat');
        end
    end
    
    
    
    %% Get & Set Methods
    methods
        % Return a path to a date-specific data folder for today scripts (creating one if it doesn't exist)
        function todayDataPath = get.TodayData(myPaths)
            todayDataPath = [myPaths.TodayData '/' datestr(now, 'yyyymmdd')];
            if ~exist(todayDataPath, 'dir'); mkdir(todayDataPath); end
        end
    end
    
    
    
    %% Object Conversion Methods
    methods
        % Convert to a structure
        function pathStruct = ToStruct(myPaths)
            %TOSTRUCT - Converts a path storage object into a structure.
            pathStruct = get(myPaths);
        end
    end
end