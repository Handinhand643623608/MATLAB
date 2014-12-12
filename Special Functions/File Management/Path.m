classdef  Path < hgsetget
% PATH - A class that wraps, manages, and provides convenience utilities for path strings in MATLAB.
%
%   SYNTAX:
%       P = Path(pathStr)
%
%   OUTPUT:
%       P:          PATH
%                   A Path object pointing to the file(s) or folder(s) at the inputted path string(s). If a
%                   cell array of strings is inputted, this will be an array of objects of the same
%                   dimensionality.
%
%   INPUT:
%       pathStr:    STRING or { STRINGS }
%                   A path string or cell array of path strings pointing to files, folders, or any
%                   combination thereof. Cell arrays must be used for multiple path string inputs, but may
%                   be of any size and dimensionality.
%
%   See also:   DIR, FILE, FILEPARTS, FOLDER, FULLFILE, LS
    
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

    
    
    %% Properties
    properties (Dependent)
        Exists                  % A Boolean indicating whether or not the file or folder exists on the computer.
        FullName                % The full name of the file or folder that the object points to, excluding the parent path.
        FullPath                % The full path string that the object points to.
        IsFile                  % A Boolean that indicates whether or not the full path points to a file.
        IsFolder                % A Boolean that indicates whether or not the full path points to a folder.
    end
    
    properties (SetAccess = protected)
        Extension               % Either 'Folder' or the extension string of the file that the full path points to.
        Name                    % The name string of the file or folder that the full path points to.
        ParentDirectory         % A path object for the directory immediately above the full path.
        ParentDrive             % The path object for drive letter (for Windows PCs only) of the full path.
    end

    properties (Access = protected)
        Directory
        Drive
    end
    
    methods (Static)
        function P = PWD
        % Gets the current working directory as a Path object.
            P = Path(pwd);
        end
    end
    
    
    
    %% Constructor Method
    methods
        function P = Path(p)
        % PATH - Constructs a new Path object or array of objects around path strings.
        %
        %   This is the constructor method for any path object. To use it, simply input a path string pointing to any
        %   file or folder on the computer currently being used. The returned object wraps the path string and
        %   automatically parses it for various components that may be useful. It also provides a number of utility
        %   methods that simplify the process of working with paths in MATLAB. See the full documentation of this class
        %   for details.
        %
        %   SYNTAX:
        %       P = Path(pathStr)
        %
        %   OUTPUT:
        %       P:          PATH
        %                   A Path object pointing to the file(s) or folder(s) at the inputted path string(s). If a cell
        %                   array of strings is inputted, this will be an array of objects of the same dimensionality.
        %
        %   INPUT:
        %       p:			STRING or { STRINGS }
        %                   A path string or cell array of path strings pointing to files, folders, or any combination
        %                   thereof. Cell arrays must be used for multiple path string inputs, but may be of any size
        %                   and dimensionality.
        %
        %   See also:   DIR, FILE, FILEPARTS, FOLDER, FULLFILE, LS
        
            if (nargin ~= 0)
				if isa(p, 'Path')
					P = p.Clone();
					return
				else
					Path.AssertStringContents(p);

					if (~iscell(p)); p = { p }; end
					P(numel(p)) = Path;
					for a = 1:numel(p)
						P(a).ParseFullPath(p{a});
					end
					P = reshape(P, size(p));
				end
            end 
        end
    end
    
    
        
    %% General Utilities
    methods
        
        % Get Methods
        function e = get.Exists(P)
            if (P.IsFile); type = 'file';
            else type = 'dir'; end
            e = logical(exist(P.FullPath, type));
        end
        function n = get.FullName(P)
            if (P.IsFile); n = [P.Name '.' P.Extension];
            else n = P.Name; end
        end
        function p = get.FullPath(P)
            if (isempty(P.Name)); p = P.Directory;
            else p = [P.Directory '/' P.FullName]; end
        end
        function b = get.IsFile(P)
            b = ~P.IsFolder;
        end
        function b = get.IsFolder(P)
            b = isempty(P.Extension);
        end
        function U = get.ParentDirectory(P)
            U = Path(P.Directory);
        end
        function D = get.ParentDrive(P)
            D = Path(P.Drive);
        end
        
        % Object Conversion Methods
        function c = ToCell(P)
        % TOCELL - Converts a Path object or array of objects into cell array of full path strings.
            c = cell(size(P));
            for a = 1:numel(P); c{a} = P(a).FullPath; end
        end
        function F = ToFile(P)
        % TOFILE - Converts a path object pointing to a file into a File object.
        %
        %   SYNTAX:
        %       F = ToFile(P)
        %       F = P.ToFile()
        %
        %   OUTPUT:
        %       F:      FILE
        %               A File object pointing to the same full path string as the inputted Path object. The only
        %               difference between the two objects is that File objects offer additional methods that are
        %               specific to files. Otherwise, the File class is a subclass of Path and therefore can use almost
        %               all of the methods that are available to its parent.
        %
        %   INPUT:
        %       P:      PATH
        %               A Path object pointing to a file that is to be converted. This path must always point to a file;
        %               inputting a reference to a folder here is an error.
        %
        %   See also:   FILE
            assert(P.IsFile, 'Only paths to files may be converted into a file object.');
            F = File(P);
        end
        function s = ToString(P)
        % TOSTRING - Converts a path object into an equivalent string representation.
        %
        %   This function extracts and returns the full path string contained in the inputted Path object. It
        %   essentially accomplishes the same thing as calling the FullPath property for a Path object but also works
        %   with arrays of objects, for which the output is formatted into a cell array that is the same size as the
        %   inputted array.
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

        % Directory Searching Methods
        function P = Contents(P)
        % CONTENTS - Gets a list of all file and folder contents in a directory.
            assert(P.IsFolder, 'Contents can only be retrieved for paths to directories, not files.');
            P = Path(contents(P.FullPath));
		end
        function F = FileContents(P)
        % FILECONTENTS - Gets a list of all files in a directory.
        %
        %   SYNTAX:
        %       F = FileContents(P)
        %       F = P.FileContents()
        %
        %   OUTPUT:
        %       F:      FILE or [ FILES ]
        %               A File object or array of objects representing a list of all files contained within the folder
        %               that the inputted Path object points to. The number of File objects in the array depends on the
        %               number of files that are in the folder, but any outputted array will always be one-dimensional
        %               with individual files placed along the first dimension (i.e. rows). Multiple entries will always
        %               be listed in ascending alphabetical order (A-Z).
        %
        %   INPUT:
        %       P:      PATH
        %               A single Path object pointing to a directory on any computer hard drive. This path must always
        %               point to a folder; inputting a reference to a file here is an error.
        %
        %   See also:   DIR, FILE, FOLDER, LS
            P.AssertSingleObject();
            assert(P.IsFolder, 'Contents can only be retrieved for paths to directories, not files.');
            allFiles = dir(P.FullPath);
            allFiles([allFiles.isdir]) = [];
            nameStrs = {allFiles.name}';
            pathStrs = cellfun(@(x) [P.FullPath '/' x], nameStrs, 'UniformOutput', false);
            F = File(pathStrs);
        end
        function F = FileSearch(P, query)
        % FILESEARCH - Searches for a specific file inside of a folder.
        %
        %   This method searches for files matching a specified signature inside of a directory, pointed to by the
        %   inputted Path object. Any folders nested inside of this directory are excluded from the search and cannot be
        %   returned by this function.
        %
        %   PERFORMING SEARCHES:        
        %   In order to find references to specific files, the query parameter of this method must be used. This query
        %   string is compared against the full file names (including extensions) of each file in the directory that P
        %   references. Any files whose names match the query signature will be returned as File objects in the ouput
        %   array. 
        %
        %   The actual searching procedure is accomplished using the MATLAB-native REGEXPI function to compare file
        %   names with the query string. Specifically, this query string is used as the expression argument for that
        %   REGEXPI. Thus, any inputs that would be acceptable for that function will also be acceptable here, including
        %   string that use metacharacters. For more information on string matching through regular expressions and on
        %   the use of metacharacters, see the MATLAB documentation for REGEXP. 
        %
        %   SYNTAX:
        %       F = FileSearch(P, query)
        %       F = P.FileSearch(query)
        %
        %   OUTPUT:
        %       F:          FILE or [ FILES ]
        %                   A File object or array of objects listing all of the files contained in the searched
        %                   directory whose names match the query signature. Multiple matches will always be listed in a
        %                   one-dimensional array in ascending alphabetical order by file name (i.e. in the same order
        %                   that they are found). If no files matching the query are found, an empty File object array
        %                   is returned and a warning is displayed in the MATLAB console window.
        %
        %   INPUTS:
        %       P:          PATH
        %                   A single Path object pointing to the directory that is to be searched. This path must always
        %                   be a singleton and must always point to a folder; inputting arrays of objects or a file
        %                   reference is an error.
        %
        %       query:      STRING
        %                   A string search query used to identify specific files in the directory that P points to.
        %                   This parameter is compared against each of the file names in that directory using regular
        %                   expressions. Any file whose name contains this query signature will be included in the
        %                   returned File array. Letter casing is ignored.
        %   
        %   See also:   FILECONTENTS, REGEXP, REGEXPI
            P.AssertSingleObject();
            assert(P.IsFolder, 'Files may only be searched for in folders, not in other files.');
            assert(~isempty(query) && ischar(query), 'The query parameter must contain a single string.');
            
            F = P.FileContents();
            idsMatch = regexpi(F.ToCell(), ['.*' query '.*']);
            idsMatch = ~cellfun(@isempty, idsMatch);
            
            if (~any(idsMatch))
                warning(['No files with the signature %s were found in %s.\n'...
                         'Check to ensure that the file exists in this folder'],...
                         query,...
                         P.FullPath);
                F = File;
                return;
            end
            
            F(~idsMatch) = [];
        end        
        
        % Navigation Methods
        function NavigateTo(P)
        % NAVIGATETO - Changes MATLAB's current working directory to the folder that the path object points to.
        %
        %   This method changes the MATLAB working directory to the folder pointed to by P. The working directory is
        %   whatever folder is listed in the address bar that by default is found immediately above the command window
        %   in the IDE. It is also the folder whose contents are listed in the Current Folder pane of the IDE. 
        %
        %   Essentially, this function works just like the native CD command except that it also allows for navigating
        %   to the parent directories of any inputted file references. The native CD command throws an error if a
        %   path-to-file string is inputted. Here, if P points to a file, then this function switches the working
        %   directory to that file's parent folder. Otherwise, it navigates to whatever directory P references.
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
            if (P.IsFile); P.ParentDirectory.NavigateTo();
            else cd([P.FullPath '/']);
            end
        end
        function View(P)
		% VIEW - Opens a directory or a file's parent directory in Windows Explorer.
            assert(ispc, 'This function is only available on Windows PCs.');
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
		%		C:		PATH or [ PATHS ]
		%				An identical clone of the path(s) in P. Properties of this output that contain objects do not
		%				reference the same objects as the corresponding properties in P.
		%
		%	INPUT:
		%		P:		PATH or [ PATHS ]
		%				A path object or array of objects that are to be copied.
			C(numel(P)) = Path;
			for a = 1:numel(pathStr)
				C(a).Extension = P(a).Extension;
				C(a).Name = P(a).Name;
				C(a).ParentDirectory = P(a).ParentDirectory.Clone();
				C(a).ParentDrive = P(a).ParentDrive.Clone();
			end
			C = reshape(C, size(P));
		end
		function b = CopyTo(P, destination)
		% COPYTO - Copies source files and folders to a destination path.
		%
		%	COPYTO copies files and folders to a location that is accessible by the computer. This method works just
		%	like copying and pasting does in the computer's file viewer and like the MATLAB-native function COPYFILE.
		%	
		%	SYNTAX:
		%		b = P.CopyTo(destination)
		%		b = CopyTo(P, destination)
		%
		%	OUTPUT:
		%		b:				BOOLEAN or [ BOOLEANS ]
		%						A Boolean indicating whether or not the copy operation was successful. If it was
		%						completed successfully, a logical TRUE is returned.
		%
		%	INPUT:
		%		P:				PATH or [ PATHS ]
		%						A path object or array of objects referencing files or folders that will be copied over
		%						to DESTINATION. Object arrays of any size and dimensionality are supported.
		%
		%		destination:	STRING or PATH
		%						A path string or object referencing the destination directory into which the files
		%						referenced by P will be copied. This must always point to a directory and not to a file.
		%						Any destination directories that do not exist will be created automatically.
		%
		%	See also: COPYFILE
			D = Path(destination);
			D.AssertSingleObject();
			assert(~D.IsFile,...
				'The destination of a copy must reference a directory. Files cannot be copied to other files.');
			if (~D.Exists); mkdir(D); end
			
			b = false(size(P));
			for a = 1:numel(P)
				[b(a), ~, ~] = copyfile(P.FullPath, D.FullPath);
			end
		end
		
    end
    
    methods (Static)
        function P = Where(fileName)
        % WHERE - Returns the path to the directory containing a function or file.
            if (isa(fileName, 'Path') || isa(fileName, 'File'))
                P = fileName.ParentDirectory;
                return;
            end
            P = Path(where(fileName));
        end
    end
    
    
    
    %% Overloaded MATLAB Methods
    methods
                        
        function addpath(P)
		% ADDPATH - Adds a path to MATLAB's current working path list.            
            for a = 1:numel(P); addpath(P(a).FullPath); end
        end
        function cd(P)
		% CD - Navigates to the inputted directory or parent directory if the object points to a file.
		%
		%   This method is provided as a shortcut for the NAVIGATETO method and overloads the native CD function for
		%   Path objects.
		%
		%   See also:   CD
            P.NavigateTo()
        end
        function display(P)
        % DISPLAY - Displays information about the Path object in the console window.
        %
        %   This method organizes and formats Path object information before displaying it in the console window. The
        %   information that is displayed is different depending on the number of objects that are inputted. For
        %   singleton objects, this function prints a more detailed view of the Path instance. For arrays of Path 
        %   objects, this function prints a list of full path strings only.
        %
        %   DISPLAY is called automatically whenever operations returning a Path object are invoked without using the
        %   semicolon output suppressor. This includes the act of invoking an existing object in a function, script, or
        %   in the console (i.e. by typing P and pressing enter if "P" is the name of a Path object).
        %
        %   SYNTAX:
        %       display(P)
        %       P.display()
        %
        %   INPUT:
        %       P:      PATH or [ PATHS ]
        %               A Path object or array of objects for which information will be displayed in the MATLAB console.
        %
        %   See also:   DISP, DISPLAY, FPRINTF
            if (numel(P) == 1)
                if (P.IsFile); entityStr = 'File';
                else entityStr = 'Folder'; end
                fprintf(1,...
                    ['\n',...
                     '%s Reference:\n\n',...
                     '\t    Path:\t\t%s\n',...
                     '\n',...
                     '\t  Exists:\t\t%s\n',...
                     '\t  IsFile:\t\t%s\n',...
                     '\tLocation:\t\t%s\n',...
                     '\t    Name:\t\t%s\n',...
                     '\n',...
                     ],...
                     entityStr,...
                     P.FullPath,...
                     Path.BooleanString(P.Exists),...
                     Path.BooleanString(P.IsFile),...
                     P.ParentDirectory.ToString(),...
                     P.FullName);
            else
                pathCell = cell(numel(P), 1);
                for a = 1:numel(P); pathCell{a} = P(a).FullPath; end
                formatStr = [repmat('\t%s\n', 1, numel(P)) '\n'];
                fprintf(1,...
                    ['\n',...
                     '(%d x %d) Array of Path References:\n\n',...
                     formatStr],...
                     size(P, 1),...
                     size(P, 2),...
                     pathCell{:});
            end      
        end
        function rmpath(P)
		% RMPATH - Removes a path from MATLAB's current working path list.
			for (a = 1:numel(P)); rmpath(P(a).FullPath); end
		end
			
        function str        = char(P)
        % CHAR - Converts a Path object into a fully formed path string.
        %
        %   This method is provided to allow implicit object casting for functions where use of the full Path object is
        %   not supported.
        %
        %   See also: CHAR, TOCELL, TOSTRING
            str = P.ToString();
        end
        function exists     = exist(P, type)
            % EXIST - Checks for the existence of a file or folder at the specified path.
            P.AssertSingleObject();
            exists = exist(P.FullPath, type);
        end        
        function paths      = genpath(P)
		% GENPATH - Recursively generates directory paths starting at the inputted object's path.
            P.AssertSingleObject();
            paths = Path(genpath(P.FullPath));
        end
        function catP       = horzcat(varargin)
            
            strCheck = cellfun(@ischar, varargin(2:end));
            pathCheck = cellfun(@(x) isa(x, 'Path'), varargin);
            
            
            if (all(strCheck))
                pathAppend = cellfun(@char, varargin, 'UniformOutput', false);
                catP = Path([pathAppend{:}]);
                return
            end
            
            if (all(pathCheck))
                
                warning('Object array concatenation is currently not working properly. Cancelling operation.');
                return;
                
                % Check that all inputs have the same number of dimensions
                dimsInP = cellfun(@ndims, varargin);
                if (~all(dimsInP == dimsInP(1)))
                    error('Only arrays with equivalent numbers of dimensions can be concatenated.');
                end
                
                % Get the sizes of all object arrays
                numDims = dimsInP(1);
                idsSize = 1:numDims;
                idsSize(2) = [];
                szInP = cellfun(@size, varargin, 'UniformOutput', false);
                
                % Ensure that sizes are equal over all but the second dimension
                szCheck = all(cellfun(@(x) (isequal(x(idsSize), szInP{1}(idsSize))), szInP(2:end)));
                if (~szCheck)
                    error('Arrays must be equivalently sized over all dimensions except in numbers of columns.');
                end
                
                % Determine the final size of the output Path array
                numColsInP = cellfun(@(x) size(x, 2), varargin(2:end));
                szCatP = szInP{1};
                szCatP(2) = szCatP(2) + sum(numColsInP);
                
                % Initialize the outputs
                catP(prod(szCatP)) = Path;
                
                % Fill in the output path array by sequentially indexing each separate inputted array
                a = 1;
                c = 1;
                while (a <= length(varargin))
                    b = 1;
                    while (b <= numel(varargin{a}))
                        catP(c) = varargin{a}(b);
                        c = c + 1;
                        b = b + 1;
                    end
                    a = a + 1;
                end
                
                % 
                permOrder = 1:numDims;
                temp = permOrder(end);
                permOrder(end) = permOrder(2);
                permOrder(2) = temp;
                
                catP = reshape(catP, szCatP(permOrder));
                catP = permute(catP, permOrder);

            else
                error('NA');
            end
        end
        function [s, m, id] = mkdir(P)
        % MKDIR - Creates the directory at the specified path.
        %
        %   See also: MKDIR
            [s, m, id] = mkdir(P.FullPath);
		end
        function catP       = vertcat(P, varargin)
            
            if (~all(cellfun(@(x) isa(x, 'Path'), varargin)))
                error('Vertical concatenation only applies to forming arrays of path objects.');
            end
            
            warning('Object array concatenation is currently not working properly. Cancelling operation.');
            return;
            
            szP = size(P);
            
            newP(szP(1) + length(varargin), szP(2)) = Path;
            
        end

    end
    
    
    
    %% Private Class Methods
    methods (Access = protected)
        function AssertSingleObject(P)
            % ASSERTSINGLEOBJECT - Throws an error if more than one Path object is supplied to a function.
            if (numel(P) > 1)
                error('Only one Path object may be inputted at a time.');
            end
        end
        function ParseFullPath(P, pathStr)
		% PARSEFULLPATH - Deconstructs a full path string and populates the Path object properties with it.
            
            P.AssertSingleObject();
            Path.AssertSingleString(pathStr);
            
            [p, n, e] = fileparts(pathStr);
            
            P.Directory = Path.FormatPathString(p);
            P.Name = n;
            P.Extension = Path.FormatExtensionString(e);
            
            if (ispc)
                drivePattern = '^([^\\/]:).*';
                driveLetter = regexp(P.Directory, drivePattern, 'tokens');
                P.Drive = driveLetter{1}{1};
            else
                P.Drive = '/';
            end
        end 
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
        
        function s = BooleanString(bool)
        % BOOLEANSTRING - Converts Boolean values into equivalent string representations.
            if (bool); s = 'true'; 
            else s = 'false'; end
        end
        function e = FormatExtensionString(e)
        % FORMATEXTENSIONSTRING - Removes dots from file extension strings.
            if (iscell(e)); e = cellfun(@(x) strrep(x, '.', ''), e, 'UniformOutput', false);
            else e = strrep(e, '.', ''); end
        end
        function p = FormatPathString(p)
        % FORMATPATHSTRING - Forces the use of the universal separator character and removes trailing separators.
            p = strrep(p, '\', '/');
            if (p(end) == '/'); p(end) = []; end
        end
    end
                
    
    
end