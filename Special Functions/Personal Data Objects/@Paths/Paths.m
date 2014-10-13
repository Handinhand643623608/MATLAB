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
%       20140804:   Updated the working code directory across my computers, which received a much needed update today.
%                   Calling the working directory "svnSandbox" no longer makes sense; I haven't used SVN seriously in a
%                   very long time.
%       20140929:   Removed the GetEEG and GetBOLD methods and created new dependent object properties to take over
%                   their functionality. Reorganized class a bit.

   
    
    %% Important Paths
    properties (Dependent)
        
        InfraslowBOLD       % A list of paths to all current infraslow BOLD data objects.
        InfraslowEEG        % A list of paths to all current infraslow EEG data objects.
        
    end
    
    properties
       
        BOLD                % The path to all BOLD data objects.
        DataObjects         % The path to all data objects.
        Desktop             % The path to the computer's desktop.
        EEG                 % The path to all EEG data objects.
        FlashDrive          % The path to a USB flash drive.
        Globals             % The path to all global functions.
        Main                % The path to the main coding workspace.
        Raw                 % The path to all raw BOLD and EEG data sets.
        TodayScripts        % The path to all today scripts.
        TodayData           % The path to where all today script data sets are saved.
        
    end
    
    
    
    %% Constructor Method
    methods
        function myPaths = Paths
            %PATHS - Constructs a personalized path storage object for frequently used computer folders.
            computerName = getenv('COMPUTERNAME');
            switch lower(computerName)
                case 'desktop'
                    myPaths.DataObjects     = Path('E:/Graduate Studies/Lab Work/Data Sets/Data Objects');
                    myPaths.Desktop         = Path('C:/Users/Josh/Desktop');
                    myPaths.FlashDrive      = Path('X:');
                    myPaths.Globals         = Path('C:/Users/Josh/Dropbox/Globals');
                    myPaths.Main            = Path('C:/Users/Josh/Dropbox/MATLAB Code');
                    myPaths.Raw             = Path('E:/Graduate Studies/Lab Work/Data Sets/Raw Data');
                    myPaths.TodayScripts    = Path('C:/Users/Josh/Dropbox/MATLAB Code/Today Scripts');
                    myPaths.TodayData       = Path('E:/Graduate Studies/Lab Work/Data Sets/Today Data');
                    
                case 'shella-bigboy1'
                    myPaths.DataObjects     = Path('C:/Users/jgrooms/Desktop/Data Sets/Data Objects');
                    myPaths.Desktop         = Path('C:/Users/jgrooms/Desktop');
                    myPaths.FlashDrive      = Path('X:');
                    myPaths.Globals         = Path('C:/Users/jgrooms/Dropbox/Globals');
                    myPaths.Main            = Path('C:/Users/jgrooms/Dropbox/MATLAB Code');
                    myPaths.Raw             = Path('S:/Josh/Data/Raw');
                    myPaths.TodayScripts    = Path('C:/Users/jgrooms/Dropbox/MATLAB Code/Today Scripts');
                    myPaths.TodayData       = Path('C:/Users/jgrooms/Desktop/Today Data');
                    
                case ''     % CABI doesn't have names evidently...
                    myPaths.DataObjects     = Path('');
                    myPaths.Desktop         = Path('/home/jgrooms/Desktop');
                    myPaths.FlashDrive      = Path('');
                    myPaths.Globals         = Path('/home/jgrooms/Dropbox/Globals');
                    myPaths.Main            = Path('/home/jgrooms/Dropbox/MATLAB Code');
                    myPaths.Raw             = Path('');
                    myPaths.TodayScripts    = Path('/home/jgrooms/Dropbox/MATLAB Code/Today Scripts');
                    myPaths.TodayData       = Path('/home/jgrooms/Desktop/Today Data');
            end
            
            % Fill in paths that can be derived
            myPaths.BOLD = [myPaths.DataObjects '/BOLD'];
            myPaths.EEG = [myPaths.DataObjects '/EEG'];
        end
    end    
    
    
    
    %% Data File Retrieval & Query Methods
    methods 
        pathList = Contents(myPaths, folder)                        % Get a list of paths to all folder contents
        pathList = Search(myPaths, folder, searchStr, varargin)     % Search through a folder for specific files 
    end    
        
    
    
    %% Shortcut Methods
    methods
        function CD(myPaths, folder)
            %CD - Quickly change the MATLAB working directory to a folder in the PATHS object.
            cd(get(myPaths, folder));
        end
    end
    
    
    
    %% Get & Set Methods
    methods    
        function boldFiles = get.InfraslowBOLD(P)
            boldFiles = Search(P, 'BOLD', 'boldObject.*', 'Ext', '.mat');
        end
        function eegFiles = get.InfraslowEEG(P)
            eegFiles = P.Search('EEG', 'eegObject.*', 'Ext', '.mat');
        end
        
        % Return a path to a date-specific data folder for today scripts (creating one if it doesn't exist)
        function todayDataPath = get.TodayData(P)
            todayDataPath = [P.TodayData '/' datestr(now, 'yyyymmdd')];
            if ~exist(todayDataPath, 'dir'); mkdir(todayDataPath); end
        end
    end
        
    
    
    %% Object Conversion Methods
    methods     
        function pathStruct = ToStruct(myPaths)
            %TOSTRUCT - Converts a path storage object into a structure.
            pathStruct = get(myPaths);
        end
    end
   
end