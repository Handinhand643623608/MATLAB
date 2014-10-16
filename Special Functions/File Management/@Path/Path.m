classdef  Path < hgsetget
    
    
%% CHANGELOG
%   Written by Josh Grooms on 20141010

    
    
    %% Properties
    
    
    properties (SetAccess = protected)
        
        FullPath;               % The full path string that the object points to.
        Extension;              % Either 'Folder' or the extension string of the file that the full path points to.
        IsFile;                 % A Boolean that indicates whether or not the full path points to a file.
        IsFolder;               % A Boolean that indicates whether or not the full path points to a folder.
        Name;                   % The name string of the file or folder that the full path points to.
        
    end
    
    properties (Dependent)
        
        ParentDirectory;        % A path object for the directory immediately above the full path.
        ParentDrive;            % The path object for drive letter (for Windows PCs only) of the full path.
        
    end
    
    
    
    
    %% Constructor Method
    methods
        function P = Path(pathStr)
            % PATH - Constructs a new Path object or array of objects around path strings.
            
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
        function parent = get.ParentDirectory(P)
            P.AssertSingleObject();
            
            if (P.IsFile); pattern = '(.*)[\\/][^\\/]+\.[^\\/]$';
            else pattern = '(.*)[\\/][^\\/]+$';
            end
            parentPath = regexp(P.FullPath, pattern, 'tokens');
            parent = Path(parentPath{1}{1}); 
        end
        function drive  = get.ParentDrive(P)
            if (ispc)
                drivePattern = '^([^\\/]:).*';
                driveLetter = regexp(P.FullPath, drivePattern, 'tokens');
                drive = Path(driveLetter{1}{1});
            else
                drive = Path('/');
            end
        end
        
        % Object Conversion Methods
        function C      = ToCell(P)
            % TOCELL - Converts a Path object or array of objects into cell array of full path strings.
            C = cell(size(P));
            for a = 1:numel(P); C{a} = P(a).FullPath; end
        end
        function F      = ToFile(P)
            % TOFILE - Converts a path object pointing to a file into a File object.
            if (~P.IsFile); error('Only paths to files may be converted into a file object.'); end
            F = File(P);
        end        
        function str    = ToString(P)
            % TOSTRING - Converts a path object into an equivalent string representation.
            str = P.FullPath; 
        end
        
        % Navigation Methods
        function NavigateTo(P)
            % NAVIGATETO - Changes MATLAB's current working directory to the directory that the path object points to. 
            P.AssertSingleObject();
            if (P.IsFile); P.ParentDirectory.NavigateTo();
            else cd([P.FullPath '/']);
            end
        end
        function ViewInExplorer(P)
            % VIEWINEXPLORER - Opens a directory or a file's parent directory in Windows Explorer.
            
            if (~ispc); warning('This function is only available on Windows PCs.'); return; end
            if (P.IsFile); P.ViewInExplorer(P.ParentDirectory);
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
            P.NavigateTo()
        end
        
        function str        = char(P)
            % CHAR - Converts a Path object into a fully formed path string.
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
            
            filePattern = '([^\\/\.]+)\.?([^\\/]*)$';
            fileParts = regexp(P.FullPath, filePattern, 'tokens');
            P.IsFolder = isempty(fileParts{1}{2});
            P.IsFile = ~P.IsFolder;
            
            P.Name = fileParts{1}{1};
            
            if (P.IsFolder); P.Extension = 'Folder';
            else P.Extension = fileParts{1}{2};
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