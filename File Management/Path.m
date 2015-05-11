% PATH - An abstract class that forms the base for File and Folder path objects.
%
%	Path Properties:
%		Exists			- Gets a Boolean indicating whether or not the file or folder exists on the computer.
%		FullPath		- Gets a string containing the full path to the stored reference.
%		Name			- Gets a string containing the name of the file or folder that the Path object points to.
%		ParentDirectory - Gets a Folder object for the directory immediately above the currently stored reference.
%		ParentDrive		- Gets a Folder object for the drive letter of the stored reference (for Windows PCs only).
%
%	Path Constructors:.
%		Resolve			- Resolves a list of path strings into lists of File and Folder objects.
%
%	Path Methods:
%		Clone			- Creates a deep copy of a Path object.
%		CopyTo			- Copies a source folder and all of its contents to a new location on a hard drive.
%		NavigateTo		- Changes the MATLAB working directory to the one referenced by the Path object.
%		ToCell			- Converts a Path object or array of objects into a cell array of full path strings.
%		ToString		- 
%		View			- Opens a directory or a file's parent directory in Windows Explorer.
%
%	Path Static Methods:
%		HasExtension	- Determines whether or not path strings have file extension components.
%		Parts			- Breaks path strings down into directory, file name, and file extension components.
%		
%	Path Overloads:
%		cd				- Changes the MATLAB working directory to a new folder or the parent folder of a file.
%		exist			- Determines whether or not files or folders exist on the computer at the specified locations.
%
%   See also: CONTENTS, DIR, FILE, FOLDER, FULLFILE, LS, SEARCH, WHERE
    
%% CHANGELOG
%   Written by Josh Grooms on 20141010
%       20141110:   Reorganized some of the properties of this class. Completely rewrote the ParseFullPath method to be
%                   more effective. Implemented some string formatting methods to ensure standardization of path
%                   components.
%       20141117:   Implemented a method for getting both file and folder contents from a path to a directory.
%		20141118:	Changed the name of the method ViewInExplorer to just View to make it easier to use.
%		20141124:	Implemented an overload for the function "rmpath" so that directories can be removed from the MATLAB
%					working path list.
%		20141210:	Implemented new methods for deep cloning path objects and for copying referenced files to a new
%					location accessible by the computer.
%		20141215:	Fixed some bugs related to the Clone and CopyTo methods.
%		20150224:	Implemented some new methods to make dealing with path strings easier. Finally implemented a proper
%					horizontal concatenation method for path objects. Implemented a new assertion for directory references.
%		20150325:	Fixed a bug in "genpath" that prevented it from working in Linux. On those file systems, colons separate
%					created path lists from the native "genpath" instead of the semicolons that are used in the Windows
%					environment.
%       20150428:   Implemented new functions that collect and search through subfolders of a directory.
%		20150507:	Overhauled the class documentation to summarize all of the properties and methods that are available.
%		20150510:	Completed a major rewrite of most of this class. Much of the previous functionality has been moved to a
%					new FOLDER object class. PATH is now an abstract base supporting both FOLDER and FILE objects, which
%					should always have been separate.



%% CLASS DEFINITION 
classdef (Abstract) Path < handle & Entity
    
	
    
    %% DATA
	properties (Abstract, Dependent)
		FullPath                % Gets a string containing the full path to the stored reference.
	end
	
    properties (Dependent)
        Exists                  % Gets a Boolean indicating whether or not the file or folder exists on the computer.
		ParentDirectory         % Gets a Folder object for the directory immediately above the currently stored reference.
		ParentDrive             % Gets a Folder object for the drive letter of the stored reference (for Windows PCs only).
	end
    
    properties (SetAccess = protected)
        Name                    % Gets a string containing the name of the file or folder that the Path object points to.
    end

    properties (Access = protected)
        Directory				% The data behind ParentDirectory.
        Drive					% The data behind ParentDrive.
    end
    
    
    
	%% PROPERTIES
    methods
        function e = get.Exists(P)
			if (isa(P, 'File')); type = 'file'; 
            else type = 'dir'; end
            e = logical(exist(P.FullPath, type));
		end
        function U = get.ParentDirectory(P)
			U = Folder(P.Directory);
        end
        function D = get.ParentDrive(P)
            D = Folder(P.Drive);
		end
	end
	
	
	
    %% CONSTRUCTORS
    methods
        function P = Path(p)
        % PATH - Constructs a new Path object from a path string.
		%
		%	This is the base constructor for any File and Folder objects that are created. Because the Path class is
		%	abstract, this constructor cannot be invoked directly. 
        %
        %   This is the constructor method for any path object. To use it, simply input a path string pointing to any file or
        %   folder on the computer currently being used. The returned object wraps the path string and automatically parses
        %   it for various components that may be useful. It also provides a number of utility methods that simplify the
        %   process of working with paths in MATLAB. See the full documentation of this class for details.
        %
        %   SYNTAX:
        %       P = Path(p)
        %
        %   OUTPUT:
        %       P:          PATH
        %                   A Path object pointing to the file(s) or folder(s) at the inputted path string(s). If a cell
        %                   array of strings is inputted, this will be an array of objects of the same dimensionality.
        %
        %   INPUT:
        %       p:			STRING
        %                   A path string pointing to a file or folder.
        %
        %   See also:   DIR, FILE, FILEPARTS, FOLDER, FULLFILE, LS

			if (nargin ~= 0 && ~isempty(p))
				if isa(p, 'Path')
					P = p.Clone();
					return
				else
					Path.AssertSingleString(p);
					P.ParseFullPath(p);
				end
			end
        end
	end
    
    methods (Static)
		function [F, D] = Resolve(p)
		% RESOLVE - Resolves a list of path strings into lists of File and Folder objects.
		%
		%	SYNTAX:
		%		[F, D] = Path.Resolve(p)
		%
		%	OUTPUTS:
		%		F:		[ M x 1 FILES ]
		%				A list of File objects referencing all of the files that are listed in the inputted array.
		%		
		%		D:		[ N x 1 FOLDERS ]
		%				A list of Folder objects referencing all of the directories that are listed in the inputted array.
		%	
		%	INPUT:
		%		p:		STRING or { STRINGS }
		%				A path string or cell array of strings referencing a mixture of files and folders on a computer.
		%
		%	See also: CONTENTS, FILE, FOLDER
		
			Path.AssertStringContents(p);
			if (~iscell(p)); p = { p }; end
			
			extpat = '.*\..*$';
			idsFolders = regexp(p, extpat);
			idsFolders = cellfun(@isempty, idsFolders);
			
			folderlist = p(idsFolders);
			filelist = p(~idsFolders);
						
			nfolders = length(folderlist);
			nfiles = length(filelist);
			
			if (nfiles > 0)
				F(nfiles, 1) = File();
				for a = 1:nfiles
					F(a) = File(filelist{a});
				end
			else
				F = [];
			end
			
			if (nfolders > 0)
				D(nfolders, 1) = Folder();
				for a = 1:nfolders
					D(a) = Folder(folderlist{a});
				end
			else
				D = [];
			end
		end
	end
	
	
	
    %% UTILITIES
	methods (Abstract, Access = protected)
		ParseFullPath(P, s)
	end
    
    methods (Static, Access = protected)
        function AssertStringContents(var)
        % ASSERTSTRINGCONTENTS - Throws an error if a variable is not a string or cell array of strings.
            assert(ischar(var) || iscellstr(var), 'Only strings or cell arrays of strings may be used with Path objects.');
        end
        function AssertSingleString(var)
		% ASSERTSINGLESTRING - Throws an error if a variable is not one single string. 
            assert(ischar(var), 'Only one string may be inputted to function at a time.');
		end
		
        function e = FormatExtensionString(e)
        % FORMATEXTENSIONSTRING - Removes dots from file extension strings.
            if (iscell(e)); e = cellfun(@(x) strrep(x, '.', ''), e, 'UniformOutput', false);
            else e = strrep(e, '.', ''); end
        end
        function p = FormatPathString(p)
        % FORMATPATHSTRING - Forces the use of the universal separator character and removes trailing separators.
			p = Path.RemoveTrailingSeparator(p);
			p = Path.FormatSeparators(p);
        end
	end
	
	methods (Static)
		
		function [d, n, e] = Parts(s)
		% PARTS - Breaks path strings down into directory, file name, and file extension components.
		%
		%	SYNTAX:
		%		[d, n, e] = Path.Parts(s)
		%
		%	OUTPUTS:
		%		d:		{ STRINGS }
		%				A cell array of strings containing the parent directories of each of the files and folders to which
		%				the inputted path array points.
		%
		%		n:		{ STRINGS }
		%				A cell array of strings containing the names of the files and folders to which the inputted path
		%				array points.
		%
		%		e:		{ STRINGS }
		%				A cell array of strings containing the extensions of any files present in the inputted path array.
		%				For path strings pointing to folders, the corresponding elements of this array will be empty strings.
		%	
		%	INPUT:
		%		s:		STRING or { STRINGS }
		%				A path string or cell array of strings to be decomposed into their constituent parts.
		%
		%	See also: PATH.HASEXTENSION
		
			Path.AssertStringContents(s);
			if (~iscell(s)); s = { s }; end			
			
			szs = size(s);
			d = cell(szs);
			n = cell(szs);
			e = cell(szs);
			
			for a = 1:numel(s)
				[d{a}, n{a}, e{a}] = fileparts(s{a});
			end
			
			d = Path.FormatSeparators(d);
			n(Cell.IsEmpty(n)) = { '' };
		end
		
		function s = FormatSeparators(s)
		% FORMATSEPARATORS - Replaces any alternative path separators in a string with the universal '/' character.
			s = strrep(s, '\', '/');
		end
		function b = HasExtension(s)
		% HASEXTENSION - Determines whether or not path strings have file extension components.
		%
		%	SYNTAX:
		%		b = Path.HasExtension(s)
		%
		%	OUTPUT:
		%		b:		[ BOOLEANS ]
		%				A Boolean array containing TRUE values wherever paths in S have file extensions and FALSE values
		%				otherwise.
		%
		%	INPUT:
		%		s:		STRING or { STRINGS }
		%				A path string or cell array of strings to be tested.
		%
		%	See also: PATH.PARTS
		
			Path.AssertStringContents(s);
			[~, ~, e] = Path.Parts(s);
			b = ~Cell.IsEmpty(e);
		end
		function s = RemoveLeadingDot(s)
		% REMOVELEADINGDOT - Removes the '.' character from the beginning of a string.
			if (s(1) == '.')
				s(1) = [];
			end
		end
		function s = RemoveLeadingSeparator(s)
		% REMOVELEADINGSEPARATOR - Removes any path separators from the beginning of a string.
			if (s(1) == '/' || s(1) == '\')
				s(1) = [];
			end
		end
		function s = RemoveTrailingDot(s)
		% REMOVETRAILINGDOT - Removes the '.' character from the end of a string.
			if (s(end) == '.')
				s(end) = [];
			end
		end
		function s = RemoveTrailingSeparator(s)
		% REMOVETRAILINGSEPARATOR - Removes any path separators from the end of a string.
			if (s(end) == '/' || s(end) == '\')
				s(end) = [];
			end
		end
	end
	
	methods
		
		% Object Conversion Methods
        function c = ToCell(P)
        % TOCELL - Converts a Path object or array of objects into cell array of full path strings.
            c = cell(size(P));
            for a = 1:numel(P); c{a} = P(a).FullPath; end
		end
        function s = ToString(P)
        % TOSTRING - Converts a path object into an equivalent string representation.
        %
        %   This function extracts and returns the full path string contained in the inputted Path object. It essentially
        %   accomplishes the same thing as calling the FullPath property for a Path object but also works with arrays of
        %   objects, for which the output is formatted into a cell array that is the same size as the inputted array.
        %
        %   SYNTAX:
        %   s = ToString(P)
        %   s = P.ToString()
        %
        %   OUTPUT:
        %       s:      STRING or { STRINGS }
        %               A string or cell array of strings containing the full path strings that were contained in the
        %               Path inputs. For single Path objects, this will be a single string (not a cell). Inputting Path
        %               arrays will generate cell arrays of path strings of the same size and dimensionality.
        %
        %   INPUT:
        %       P:      PATH or [ PATHS ]
        %               A Path object or array of objects containing path strings to files or folders on the computer
        %               currently being used. Path objects may point to anything and may be inputted as arrays of any
        %               size and dimensionality.
        
            if (numel(P) == 1)
                s = P.FullPath;
                return;
            else
                s = {P.FullPath}';
                s = reshape(s, size(P));
            end
        end
        
        % Navigation Methods
        function NavigateTo(P)
        % NAVIGATETO - Changes MATLAB's current working directory to the folder that the path object points to.
        %
        %   This method changes the MATLAB working directory to the folder pointed to by P. The working directory is whatever
        %   folder is listed in the address bar that by default is found immediately above the command window in the IDE. It
        %   is also the folder whose contents are listed in the Current Folder pane of the IDE.
        %
        %   Essentially, this function works just like the native CD command except that it also allows for navigating to the
        %   parent directories of any inputted file references. The native CD command throws an error if a path-to-file
        %   string is inputted. Here, if P points to a file, then this function switches the working directory to that file's
        %   parent folder. Otherwise, it navigates to whatever directory P references.
        %
        %   SYNTAX:
        %       NavigateTo(P)
        %       P.NavigateTo()
        %
        %   INPUT:
        %       P:      PATH
        %               A single Path object pointing to a file or folder. Arrays of objects are not supported by this
        %               function.
        %
        %   See also:   CD, PWD
            P.AssertSingleObject();
            if (isa(P, 'File')); P.ParentDirectory.NavigateTo();
            else cd([P.FullPath '/']);
            end
        end
        function View(P)
		% VIEW - Opens a directory or a file's parent directory in Windows Explorer.
            assert(ispc, 'This function is only available on Windows PCs.');
			P.AssertSingleObject();
            if (P.IsFile); P.ParentDirectory.ViewInExplorer();
            else winopen(P.FullPath);
            end
            
		end
		
		% Utilities
		function C = Clone(P)
		% CLONE - Creates deep copies of inputted path objects.
		%
		%	CLONE performs a deep copy process on PATH objects, meaning that although the output is identical to the
		%	input, the two do not contain any common object references. This is important when programming by reference
		%	in order to avoid unintentionally changing properties across class instances.
		%
		%	SYNTAX:
		%		C = P.Clone()
		%		C = Clone(P)
		%
		%	OUTPUT:
		%		C:		FILE or [ FILES ] or FOLDER or [ FOLDERS ]
		%				An identical clone of the path(s) in P. Properties of this output that contain objects do not
		%				reference the same objects as the corresponding properties in P.
		%
		%	INPUT:
		%		P:		FILE or [ FILES ] or FOLDER or [ FOLDERS ]
		%				A path object or array of objects that are to be copied.
		
			if isa(P(1), 'Folder')
				C(numel(P)) = Folder();
				for a = 1:numel(P)
					C(a) = Folder(P(a).FullPath);
				end
			else
				C(numel(P)) = File();
				for a = 1:numel(P)
					C(a) = File(P(a).FullPath);
				end
			end
			C = reshape(C, size(P));
		end
		function b = CopyTo(P, destination)
		% COPYTO - Copies source files and folders to a destination path.
		%
		%	COPYTO copies files and folders to a location that is accessible by the computer. This method works just like
		%	copying and pasting does in the computer's file viewer and like the MATLAB-native function COPYFILE.
		%	
		%	SYNTAX:
		%		b = P.CopyTo(destination)
		%		b = CopyTo(P, destination)
		%
		%	OUTPUT:
		%		b:				BOOLEAN or [ BOOLEANS ]
		%						A Boolean indicating whether or not the copy operation was successful. If it was completed
		%						successfully, a logical TRUE is returned.
		%
		%	INPUT:
		%		P:				[ FILES ] or [ FOLDERS ]
		%						A path object or array of objects referencing files or folders that will be copied over to
		%						DESTINATION. Object arrays of any size and dimensionality are supported.
		%
		%		destination:	STRING or FOLDER
		%						A path string or object referencing the destination directory into which the files referenced
		%						by P will be copied. This must always point to a directory and not to a file. Any destination
		%						directories that do not exist will be created automatically.
		%
		%	See also: COPYFILE
			
			if (~isa(destination, 'Folder')); destination = Folder(destination); end
			destination.AssertSingleObject();
			
			if (~destination.Exists); mkdir(D); end
			
			b = false(size(P));
			pb = Progress('-fast', 'Copying Files');
			if isa(P(1), 'Folder')
				for a = 1:numel(P)
					[b(a), ~, ~] = copyfile(P(a).FullPath, [destination.FullPath '/' P(a).Name]);
					pb.Update(a/numel(P));
				end
			else
				for a = 1:numel(P)
					[b(a), ~, ~] = copyfile(P(a).FullPath, [destination.FullPath '/' P(a).FullName]);
					pb.Update(a/numel(P));
				end
			end
			pb.Close();
		end

	end
    
    
    
	%% MATLAB OVERLOADS
	methods
		function cd(P)
		% CD - Navigates to the inputted directory or parent directory if the object points to a file.
		%
		%   This method is provided as a shortcut for the NAVIGATETO method and overloads the native CD function for
		%   Path objects.
		%
		%   See also: CD, PATH.NAVIGATETO, PATH.VIEW
            P.NavigateTo()
        end
		function b = exist(P)
		% EXIST - Checks for the existence of a file or folder at the specified path.
			b = reshape([P.Exists], size(P));
		end
	end
  
                
    
    
end