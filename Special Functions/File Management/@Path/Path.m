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

    
    
    %% Properties
    properties (Dependent)
        Exists                  % A Boolean indicating whether or not the file or folder exists on the computer.
        ParentDirectory;        % A path object for the directory immediately above the full path.
        ParentDrive;            % The path object for drive letter (for Windows PCs only) of the full path.
    end
    
    properties (SetAccess = protected)
        FullName;               % The full name of the file or folder that the object points to, excluding the parent path.
        FullPath;               % The full path string that the object points to.
        Extension;              % Either 'Folder' or the extension string of the file that the full path points to.
        IsFile;                 % A Boolean that indicates whether or not the full path points to a file.
        IsFolder;               % A Boolean that indicates whether or not the full path points to a folder.
        Name;                   % The name string of the file or folder that the full path points to.
    end
    
    methods (Static)
        function P = PWD
            % Gets the current working directory as a Path object.
            P = Path(pwd);
        end
    end
    
    
    
    %% Constructor Method
    methods
        function P = Path(pathStr)
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
        %       pathStr:    STRING or { STRINGS }
        %                   A path string or cell array of path strings pointing to files, folders, or any combination
        %                   thereof. Cell arrays must be used for multiple path string inputs, but may be of any size
        %                   and dimensionality.
        %
        %   See also:   DIR, FILE, FILEPARTS, FOLDER, FULLFILE, LS
        
            if (nargin ~= 0)                    
                Path.AssertStringContents(pathStr);
                
                if (~iscell(pathStr)); pathStr = { pathStr }; end
                P(numel(pathStr)) = Path;
                for a = 1:numel(pathStr)
                    P(a).ParseFullPath(pathStr{a});
                end
                P = reshape(P, size(pathStr));
            end 
        end
    end
    
    
        
    %% General Utilities
    methods
        
        % Get Methods
        function e = get.Exists(P)
            if (P.IsFile); type = 'file';
            else type = 'dir'; end
            e = exist(P.FullPath, type);
        end
        function U = get.ParentDirectory(P)
            P.AssertSingleObject();
            
            if (P.IsFile); pattern = '(.*)[\\/][^\\/]+\.[^\\/]$';
            else pattern = '(.*)[\\/][^\\/]+$';
            end
            parentPath = regexp(P.FullPath, pattern, 'tokens');
            U = Path(parentPath{1}{1}); 
        end
        function D = get.ParentDrive(P)
            if (ispc)
                drivePattern = '^([^\\/]:).*';
                driveLetter = regexp(P.FullPath, drivePattern, 'tokens');
                D = Path(driveLetter{1}{1});
            else
                D = Path('/');
            end
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
            if (~P.IsFile); error('Only paths to files may be converted into a file object.'); end
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
            F = File({allFiles.name});
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
        function ViewInExplorer(P)
            % VIEWINEXPLORER - Opens a directory or a file's parent directory in Windows Explorer.
            assert(ispc, 'This function is only available on Windows PCs.');
            if (P.IsFile); P.ParentDirectory.ViewInExplorer();
            else winopen(P.FullPath);
            end
            
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
            
            P.FullPath = regexprep(pathStr, '[\\/]$', '');
            P.FullPath = regexprep(pathStr, '\\', '/');
            
            filePattern = '([^\\/\.]*)\.?([^\\/]*)$';
            fileParts = regexp(P.FullPath, filePattern, 'tokens');
            P.IsFolder = isempty(fileParts{1}{2});
            P.IsFile = ~P.IsFolder;
            
            P.Name = fileParts{1}{1};
            
            if (P.IsFolder); 
                P.Extension = 'Folder';
                P.FullName = P.Name;
            else
                P.Extension = fileParts{1}{2};
                P.FullName = [P.Name, P.Extension];
            end 
        end 
    end
    
    methods (Static, Access = protected)    
        function AssertStringContents(var)
            % ASSERTSTRINGCONTENTS - Throws an error if a variable is not a string or cell array of strings.
            strCheck = (iscell(var) && all(cellfun(@ischar, var))) || (ischar(var));
            if (~strCheck); error('Only strings or cell arrays of strings may be used with Path objects.'); end
        end
        function AssertSingleString(var)
            % ASSERTSINGLESTRING - Throws an error if a variable is not one single string. 
            if (iscell(var) || ~isvector(var))
                error('Only one string may be inputted to function at a time.');
            end
        end        
    end
                
    
    
end