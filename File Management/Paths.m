classdef Paths < Entity
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
%		20141113:	Changed the name of the Globals property to Library to better reflect its purpose (nearly everything
%					is a global function in MATLAB and this is a library of functions I didn't write). Also changed the
%					path string to point to the appropriate folder on my flash drive after it was removed from Dropbox.
%       20141117:   Removed the path reference to a data object folder and replaced it with one that points to the
%                   general data folder on my flash drive. Fixed all other paths that depended on this.
%		20141210:	Added a path reference to the Today Data archive on my home and lab PCs. Implemented an automated
%					error message function for unsupported property access.
%       20150129:   Bug fix for TodayArchive and Raw static fields being incorrect for my home computer. I recently
%                   transferred everything that was on E:/ to newly purchased RAID1 archive HDDs (A:/) for fault tolerance.
%		20150205:	Added a path to the Release folder of my MEX compiler project in Visual Studio.
%       20150428:   Copied in the path to my work flash drive on the Linux machine at CABI. Rewrote several other static
%                   properties that explicitly used that path to depend instead on the static property.
%		20150510:	Changed hard-coded path construction to use FOLDER object constructors for compatibility with changes
%					just made to my file management code.
%		20150513:	Added in directory references for my home Ubuntu Linux installation.
%		20150612:	Added in support for MATLAB running on my Surface tablet.
   

    
    %% Important Paths
    methods (Static)
        
        function P = BOLD
        % Gets the path to all BOLD data objects.
            P = [Paths.Data '/BOLD'];
        end
        function P = Common
        % Gets the path to the commonly used data repository.
            P = [Paths.Data '/Common'];
        end
        function P = Data
        % Gets the parent directory for all research-related data objects
            P = [Paths.FlashDrive '/Data'];
        end
        function P = Desktop
        % Gets the path to the computer's desktop.
            switch (Paths.ComputerName)
                case { 'desktop', 'surface' }
                    P = Folder('C:/Users/Josh/Desktop');
				case 'linuxpc'
					P = Folder('/home/josh/Desktop');
                case 'shella-bigboy1'
                    P = Folder('C:/Users/jgrooms/Desktop');
                otherwise
                    P = Folder('/home/jgrooms/Desktop');
            end
        end
        function P = EEG
        % Gets the path to all EEG data objects.
            P = [Paths.Data '/EEG'];
        end
        function P = FlashDrive
        % Gets the path to my high-density USB flash drive.
            switch (Paths.ComputerName)
                case { 'desktop', 'surface' }
                    P = Folder('X:');
				case 'linuxpc'
					P = Folder('/media/josh/CEF83516F834FDF1');
                case 'shella-bigboy1'
                    P = Folder('X:');
                otherwise
                    P = Folder('/media/CEF83516F834FDF1');
            end
        end
        function P = Library
        % Gets a path to my global functions folder.
            P = [Paths.FlashDrive '/Code/MATLAB/Library'];
        end
        function P = Main
        % Gets the path to the main coding workspace.
            switch (Paths.ComputerName)
                case { 'desktop', 'surface' }
                    P = Folder('C:/Users/Josh/Dropbox/MATLAB Code');
				case 'linuxpc'
					P = Folder('/home/josh/Dropbox/MATLAB Code');
                case 'shella-bigboy1'
                    P = Folder('C:/Users/jgrooms/Dropbox/MATLAB Code');
                case 'bo-dv-jgroomsd'
                    P = Folder('C:/Users/joshua.grooms/Dropbox/MATLAB Code');
                otherwise
                    P = Folder('/home/jgrooms/Dropbox/MATLAB Code');
            end
        end
        function P = MATLAB
        % Gets the path to the MATLAB installation folder.
            P = Folder(matlabroot);
		end
		function p = MexCompiler
			p = Folder([Paths.FlashDrive '/Code/MATLAB/MexCompiler/x64/Release']);
		end
		function p = PWD
			p = Folder.PWD;
		end
        function P = Raw
        % Gets the path to all raw BOLD and EEG data sets.
            switch (Paths.ComputerName)
                case { 'desktop', 'surface' }
                    P = Folder('A:/Graduate Studies/Lab Work/Data/Raw Data');
                case 'shella-bigboy1'
                    P = Folder('S:/Josh/Data/Raw');
                otherwise
                    P = Folder('');
            end
		end
		function P = TodayArchive
		% Gets the path to the archive of data generated by Today Scripts.
			switch (Paths.ComputerName)
				case 'desktop'
					P = Folder('A:/Graduate Studies/Lab Work/Data/Today Data');
				case 'shella-bigboy1'
					P = [Paths.Desktop '/Today Data'];
				otherwise
					Today.InvalidPC('TodayArchive')
			end
		end
        function P = TodayData
        % Gets the path to the respository for all data generated by Today Scripts.
            P = [Paths.Data '/Today'];
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
		function InvalidPC(field)
		% INVALIDPC - Throws an error message when an unsupported computer attempts to access this class.
			error('Accessing the static property %s is not supported for the computer %s.', field, Today.ComputerName);
		end
    end
        

   
end