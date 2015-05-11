% FOLDER - A class that manages and provides utilities for path strings pointing to folders.
%
%	Folder Properties:
%		Exists			- Gets a Boolean indicating whether or not the file or folder exists on the computer.
%		FullPath		- Gets a string containing the full path to the stored reference.
%		Name			- Gets a string containing the name of the file or folder that the Path object points to.
%		ParentDirectory - Gets a Path object for the directory immediately above the currently stored reference.
%		ParentDrive		- Gets a Path object for the drive letter of the stored reference (for Windows PCs only).
%		PWD				- Gets the current working directory as a Path object.
%
%	Folder Constructors:
%		Folder
%		Where
%
%	Folder Methods:
%		Clone			- Creates a deep copy of a Folder object.
%		Contents		- Gets a list of all files and folders within a directory.
%		CopyTo			- Copies a source folder and all of its contents to a new location on the computer.
%		FileContents	- Gets a list of all files within a directory and, optionally, it subdirecories.
%		FileSearch		- Searches for specific files within a directory and, optionally, its subdirectories.
%		FolderContents	- Gets a list of all folders within a directory and, optionally, its subdirectories.
%		FolderSearch	- Searches for specific folders within a directory and, optionally, its subdirectories.
%		NavigateTo		- Changes the MATLAB working directory to the one referenced by the Folder object.
%		ToCell			- Converts Folder objects into a cell array of full path strings.
%		ToString		- 
%		View			- Opens a directory in Windows Explorer.
%	
%	Folder Overloads:
%		addpath			- Adds a directory to the MATLAB search path list.
%		cd				- Changes the MATLAB working directory to the one referenced by the Path object.
%		disp			- Displays information about the Path object in the console window.
%		exist			- Checks for the existence of a file or folder at the specified path.
%		horzcat			- Horizontally concatenates Path objects and strings to form new Path objects.
%		genpath			- Recursively generates Path objects that reference all directories under a specified path.
%		mkdir			- Creates a new directory on a hard drive at the specified path.
%		rmpath			- Removes a path from the MATLAB search path list.
%
%	See also: CONTENTS, DIR, FOLDER, PATH, SEARCH, WHERE

%% CHANGELOG
%	Written by Josh Grooms on 20150510



%% CLASS DEFINITION
classdef Folder < Path
	
	
	
	%% DATA
	properties (Dependent)
		FullPath
	end
	
	methods (Static)
        function P = PWD
        % Gets the current working directory as a Path object.
            P = Folder(pwd);
        end
	end
	
	
	
	%% PROPERTIES
	methods
		function p = get.FullPath(D)
			p = [D.Directory '/' D.Name];
		end
	end
	
	
	
	%% CONSTRUCTORS
	methods
		function F = Folder(p)
		% FOLDER - Constructs a new Folder object that references a directory on a computer hard drive.
			if (nargin == 0); p = ''; end
			F = F@Path(p);
		end
	end
	
	methods (Static)
		function D = Where(f)
        % WHERE - Identifies the directory containing a function or file.
		%
		%	SYNTAX:
		%		D = Folder.Where(f)
		%
		%	OUTPUT:
		%		D:		FOLDER
		%				A Folder object referencing the directory that contains the input path F.
		%
		%	INPUT:
		%		f:		STRING or FILE or FOLDER
		%				A single path string, File object, or Folder object whose parent directory is to be identified.
		
			if (isa(fileName, 'Path'))
                D = fileName.ParentDirectory;
			else
				Path.AssertSingleString(f);
				D = Folder(where(f));
			end
        end
	end
		
		
	
	%% UTILITIES
	methods (Access = protected)
		function ParseFullPath(D, s)
		% PARSEFULLPATH - Deconstructs a full path string and populates the Folder object properties with it.
		%
		%	INPUTS:
		%		D:		FOLDER
		%				The Folder object being constructed.
		%
		%		s:		STRING
		%				A single path string to be broken down.
		
			D.AssertSingleObject();
			Path.AssertSingleString(s);
			
			[d, n, e] = fileparts(s);
			assert(isempty(e), ['The path reference %s appears to contain an extension, which is an error for folders. \n'...
				'Check this reference to ensure that it is a folder, rename it if necessary (do not use ''.''characters), '...
				'or use File objects to reference files with extensions.'], s);
			
			D.Directory = Path.FormatPathString(d);
			D.Name = n;
			
			if (ispc)
				drivePattern = '^([^\\/]:).*';
                driveLetter = regexp(D.Directory, drivePattern, 'tokens');
                D.Drive = driveLetter{1}{1};
			else
                D.Drive = '/';
			end
		end
	end
	
	methods
        function [F, D] = Contents(P)
        % CONTENTS - Gets a list of all files and folders within a directory.
		%
		%	SYNTAX:
		%		[F, D] = P.Contents()
		%
		%	OUTPUTS:
		%		F:		[ N x 1 FILES ]
		%				A list of File objects referencing all of the files contained in the directory path P.
		%		
		%		D:		[ M x 1 FOLDERS ]
		%				A list of Folder objects referencing all of the immediate subdirectories of D.
		%
		%	INPUT:
		%		P:		FOLDER
		%				A single Folder object referencing the directory whose contents are to be obtained.
		%
		%	See also:	FOLDER.FILECONTENTS, FOLDER.FILESEARCH, FOLDER.FOLDERCONTENTS, FOLDER.FOLDERSEARCH
		
            P.AssertSingleObject();
            [F, D] = Path.Resolve(contents(P.FullPath));
		end
        function F = FileContents(D, includeSubfolders)
        % FILECONTENTS - Gets a list of all files within a directory and, optionally, its subdirectories.
        %
        %   SYNTAX:
        %       F = D.FileContents()
		%		F = D.FileContents(includeSubfolders)
        %
        %   OUTPUT:
		%		F:					[ M x 1 FILES ]
		%							A list of File objects referencing all of the files in the directory path D. If the
		%							option to gather files from subfolders is used, then this list will contain all files
		%							from all folders that are members of the tree under D.
		%
        %   INPUT:
        %       D:					FOLDER
		%							A single Folder object referencing the directory whose file contents are to be obtained.
        %
		%	OPTIONAL INPUT:
		%		includeSubfolders:	BOOLEAN
		%							A Boolean indicating whether or not to gather files from all subdirectories of the path
		%							D. Inputting TRUE for this argument recursively aggregates file references from the
		%							entire directory tree starting with the input path.
		%							DEFAULT: false
		%
        %   See also: FOLDER.CONTENTS, FOLDER.FILESEARCH, FOLDER.FOLDERCONTENTS, FOLDER.FOLDERSEARCH
		
			if (nargin == 1); includeSubfolders = false; end
			
            D.AssertSingleObject();
			
			[F, folders] = D.Contents();
			if (includeSubfolders)
				for a = 1:length(folders)
					F = cat(1, F, folders(a).FileContents(true));
				end
			end
        end
        function F = FileSearch(D, query, includeSubfolders)
        % FILESEARCH - Searches for specific files within a directory and, optionally, its subdirectories.
        %
        %   This method searches for files matching a specified signature inside of a directory, pointed to by the inputted
        %   Folder object. It can also search for files within the subfolders of the inputted path.
        %
        %   PERFORMING SEARCHES:		
        %		In order to find references to specific files, the query string is compared against the full file names
        %		(including extensions) of each file in the directory that D references. Any files whose names match the query
        %		signature will be returned as File objects in the ouput array.
        %
        %		The actual searching procedure is accomplished using the MATLAB-native REGEXPI function to compare file names
        %		with the query string. Query strings are used as the EXPRESSION argument for REGEXPI, and any inputs that
        %		would be acceptable for that function will also be acceptable here, including metacharacters. For more
        %		information on string matching through regular expressions and on the use of metacharacters, see the MATLAB
        %		documentation for REGEXP.
        %
        %   SYNTAX:
        %       F = P.FileSearch(query)
		%		F = P.FileSearch(query, includeSubfolders)
        %
        %   OUTPUT:
        %       F:					[ M x 1 FILES ]
		%							A list of File objects referencing all of the files whose names match the inputted search
		%							query. If the option to search through subfolders is used, then this list will also
		%							contain any matches from folders that are deeper members of the tree under D.
		%
        %   INPUTS:
        %       D:					FOLDER
		%							A single Folder object referencing the directory whose file contents are to be searched.
        %
        %       query:				STRING
        %							A string search query used to identify specific files in the directory that D points to.
        %							This parameter is compared against each of the file names in that directory using regular
        %							expressions. Any file whose name contains this query signature will be included in the
        %							returned File object array. Letter casing is ignored.
		%
		%	OPTIONAL INPUTS:
		%		includeSubfolders:	BOOLEAN
		%							A Boolean indicating whether or not to search for files within the subdirectories of the
		%							path in D. Inputting TRUE for this argument lets FileSearch return results that are
		%							located beyond the first level of the tree starting with D.
		%							DEFAULT: false
        %   
        %   See also:   FOLDER.CONTENTS, FOLDER.FILECONTENTS, REGEXP, REGEXPI
		
			if (nargin == 2); includeSubfolders = false; end
			
            D.AssertSingleObject();
			Path.AssertSingleString(query);
            
            F = D.FileContents(includeSubfolders);
            idsNoMatch = regexpi({ F.FullName }', query);
            idsNoMatch = cellfun(@isempty, idsNoMatch);
            
            if (all(idsNoMatch))
                warning(['No files with the signature %s were found in %s.\n'...
                         'Check to ensure that the file exists in this folder'],...
                         query,...
                         D.FullPath);
                F = File();
                return;
            end
            
            F(idsNoMatch) = [];
        end
		function D = FolderContents(P, includeSubfolders)
        % FOLDERCONTENTS - Gets a list of all folders within a directory and, optionally, its subdirectories.
		%
		%	SYNTAX:
		%		D = P.FolderContents()
		%		D = P.FolderContents(includeSubfolders)
		%
		%	OUTPUT:
		%		D:					[ M x 1 FOLDERS ]
		%							A list of Folder objects referencing all of the folders in the directory path D. If the
		%							option to gather subfolders is used, then this list will contain all folders located in 
		%							the tree under D.
		%
		%	INPUT:
		%		P:					FOLDER
		%							A single Folder object referencing the directory whose subfolders are to be obtained.
		%
		%	OPTIONAL INPUT:
		%		includeSubfolders:	BOOLEAN
		%							A Boolean indicating whether or not to gather all subdirectories of the path in D.
		%							Inputting TRUE for this argument recursively aggregates folder references from the entire
		%							directory tree starting with the input path.
		%							DEFAULT: false
		%
		%	See also: FOLDER.CONTENTS, FOLDER.FILECONTENTS, FOLDER.FILESEARCH, FOLDER.FOLDERSEARCH
		
			if (nargin == 1); includeSubfolders = false; end
			
            P.AssertSingleObject();
			
			[~, D] = P.Contents();
			if (includeSubfolders)
				for a = 1:length(D)
					D = cat(1, D, D(a).FolderContents(true));
				end
			end
        end
		function D = FolderSearch(P, query, includeSubfolders)
        % FOLDERSEARCH - Searches for specific folders within a directory and, optionally, its subdirectories.
		%
		%	SYNTAX:
		%		D = P.FolderSearch(query)
		%		D = P.FolderSearch(query, includeSubfolders)
		%
		%	OUTPUT:
		%		D:					[ M x 1 FOLDERS ]
		%							A list of Folder objects referencing all of the folders whose names match the inputted
		%							search query. If the option to search through subfolders is used, then this list will
		%							also contain any matches from folders that are deeper members of the tree under D.
		%
		%	INPUTS:
		%		P:					FOLDER
		%							A single Folder object referencing the directory whose subfolders are to be searched.
		%		
		%		query:				STRING
		%							A string query used to identify specific folders within the directory that D points to.
		%							This argument is compared against each of the folder names in that directory using
		%							regular expressions. Any folder whose name contains this query signature will be included
		%							in the returned Folder object array. Letter casing is ignored.
		%	
		%	OPTIONAL INPUT:
		%		includeSubfolders:	BOOLEAN
		%							A Boolean indicating whether or not to search for folders within the subdirectories of
		%							the path in D. Inputting TRUE for this argument lets FolderSearch return results that are
		%							located in beyond the first level of the tree starting with D.
		%							DEFAULT: false
		%
		%	See also: FOLDER.CONTENTS, FOLDER.FILECONTENTS, FOLDER.FILESEARCH, FOLDER.FOLDERCONTENTS
		
			if (nargin == 2); includeSubfolders = false; end
			
			P.AssertSingleObject();
			Path.AssertSingleString(query);
			
			D = P.FolderContents(includeSubfolders);
			idsNoMatch = regexpi({ P.Name }', query);
			idsNoMatch = cellfun(@isempty, idsNoMatch);
			
			if (all(idsNoMatch))
                warning(['No folders with the signature %s were found in %s.\n'...
                         'Check to ensure that the folder exists.'],...
                         query,...
                         P.FullPath);
                D = Folder();
                return;
			end
			
			D(idsNoMatch) = [];
		end
	end
	
	
	
	%% MATLAB OVERLOADS
    methods
        function addpath(D)
		% ADDPATH - Adds a path to MATLAB's current working path list.
            for a = 1:numel(D); addpath(D(a).FullPath); end
		end
        function rmpath(P)
		% RMPATH - Removes a path from MATLAB's current working path list.
			for (a = 1:numel(P)); rmpath(P(a).FullPath); end
		end
        function G = genpath(P)
		% GENPATH - Recursively generates directory paths starting at the inputted object's path.
		%
		%	Calling this function is the same as calling the class method FOLDERCONTENTS with the INCLUDESUBFOLDERS argument
		%	set to TRUE.
		%
		%	See also: ADDPATH, FOLDER.ADDPATH, FOLDER.RMPATH, FOLDER.FOLDERCONTENTS, GENPATH, RMPATH
            P.AssertSingleObject();
			G = P.FolderContents(true);
        end
        function P = horzcat(D, varargin)
		% HORZCAT - Performs horizontal concatenation between Folder objects and strings.
			
			assert(isa(D, 'Folder'), 'Path concatenation can only occur when starting with a directory reference.');
			Path.AssertStringContents(varargin);
						
			append = [varargin{:}];
			nd = numel(D);
			if Path.HasExtension(append)
				P(nd) = File();
				for a = 1:nd
					P(a) = File([D(a).FullPath append]);
				end				
			else
				P(nd) = Folder();
				for a = 1:nd
					P(a) = Folder([D(a).FullPath append]);
				end
			end
        end
        function [s, m, id] = mkdir(D)
        % MKDIR - Creates the directory at the specified path.
        %
        %   See also: MKDIR
            [s, m, id] = mkdir(D.FullPath);
		end
	end  
	
	
end