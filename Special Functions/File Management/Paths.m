classdef Paths < hgsetget
% PATHS - A personalized class for storing and managing frequently used computer paths.
%
%   SYNTAX:
%   P = Paths.PropertyName
%
%   OUTPUT:
%   P:      PATH
%           A Path object that references the requested directory. The specific path that is returned depends on the
%           computer that this class is invoked on; full paths will differ from one another between my work and home
%           computers. Computer identities are currently resolved using environment variables.

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
%       20141016:   Converted this into a makeshift static class so that paths are easier to access. Removed access to
%                   infraslow object paths (this is to be taken over by the corresponding Files class). Removed all
%                   other properties and methods that worked with the non-static Paths class.
%       20141110:   Changed the behavior of the ComputerName method to always return an all lowercase name. Updated the
%                   properties that use this method accordingly. Implemented a new Common static property to hold a
%                   reference to the folder containing some commonly used data sets.
   
    
    %% Important Paths
    methods (Static)
        
        function P = BOLD
        % Gets the path to all BOLD data objects.
            P = [Paths.DataObjects '/BOLD'];
        end
        function P = Common
        % Gets the path to the commonly used data repository.
            P = [Paths.FlashDrive '/Data/Common'];
        end
        function P = DataObjects
        % Gets the parent directory for all research-related data objects
             switch (Paths.ComputerName)
                case 'desktop'
                    P = Path('E:/Graduate Studies/Lab Work/Data Sets/Data Objects');
                case 'shella-bigboy1'
                    P = Path('C:/Users/jgrooms/Desktop/Data Sets/Data Objects');
                otherwise
                    P = Path('');
            end
        end
        function P = Desktop
        % Gets the path to the computer's desktop.
            switch (Paths.ComputerName)
                case 'desktop'
                    P = Path('C:/Users/Josh/Desktop');
                case 'shella-bigboy1'
                    P = Path('C:/Users/jgrooms/Desktop');
                otherwise
                    P = Path('/home/jgrooms/Desktop');
            end
        end
        function P = EEG
        % Gets the path to all EEG data objects.
            P = [Paths.DataObjects '/EEG'];
        end
        function P = FlashDrive
        % Gets the path to my high-density USB flash drive.
            switch (Paths.ComputerName)
                case 'desktop'
                    P = Path('X:');
                case 'shella-bigboy1'
                    P = Path('X:');
                otherwise
                    error('Flash drive identity on this computer is unknown.');
            end
        end
        function P = Globals
        % Gets a path to my global functions folder.
             switch (Paths.ComputerName)
                case 'desktop'
                    P = Path('C:/Users/Josh/Dropbox/Globals');
                case 'shella-bigboy1'
                    P = Path('C:/Users/jgrooms/Dropbox/Globals');
                otherwise
                    P = Path('/home/jgrooms/Dropbox/Globals');
            end
        end
        function P = Main
        % Gets the path to the main coding workspace.
            switch (Paths.ComputerName)
                case 'desktop'
                    P = Path('C:/Users/Josh/Dropbox/MATLAB Code');
                case 'shella-bigboy1'
                    P = Path('C:/Users/jgrooms/Dropbox/MATLAB Code');
                otherwise
                    P = Path('/home/jgrooms/Dropbox/MATLAB Code');
            end
        end
        function P = MATLAB
        % Gets the path to the MATLAB installation folder.
            P = Path(matlabroot);
        end
        function P = Raw
        % Gets the path to all raw BOLD and EEG data sets.
            switch (Paths.ComputerName)
                case 'desktop'
                    P = Path('E:/Graduate Studies/Lab Work/Data Sets/Raw Data');
                case 'shella-bigboy1'
                    P = Path('S:/Josh/Data/Raw');
                otherwise
                    P = Path('');
            end
        end
        function P = TodayData
        % Gets the path to the respository for all data generated by Today Scripts.
            switch (Paths.ComputerName)
                case {'desktop', 'shella-bigboy1'}
                    P = [Paths.FlashDrive '/Data/Today'];
                otherwise
                    P = Path('/home/jgrooms/Desktop/Today Data');
            end
        end
        function P = TodayScripts
        % Gets the path to the folder containing Today Scripts.
            P = [Paths.Main '/Today Scripts'];
        end
        
    end
    
    methods (Static, Access = private)
        function name = ComputerName
            % Gets the name of the computer that is currently being used.
            name = lower(getenv('COMPUTERNAME'));
        end
    end
        

   
end