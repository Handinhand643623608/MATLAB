classdef File < Path
% FILE - A class that manages and provides utilities for Path objects that point to files instead of directories.
%
%   SYNTAX:
%       F = File(P)
%
%   OUTPUT:
%       F:      FILE
%               A File object or array of objects that is equivalent in size to the inputted path(s). This output may
%               then use all of the utility functions associated with this class.
%
%   INPUT:
%       P:      PATH or [ PATHS ] or STRING or { STRING }
%               A Path object, array of objects, path string, or cell array of path strings pointing to one or more
%               files. This argument must always refer to a file, defined here as anything with a visible extension.
%               Folders and files without extensions are not supported and will trigger errors.

%% CHANGELOG
%   Written by Josh Grooms on 20141010
    


    %% Properties
    
    properties
        IsOpen = false;         % A Boolean indicating whether or not a data stream has been opened for the file.
    end
    
    properties (Access = private)
        FID = NaN;              % The numeric handle to an open data stream for the file this object contains.
        Permission = '';        % The string read/write permission that was used to open the file's data stream.
    end
    
    
    
    %% Constructor & Destructor Methods
    methods
        function F = File(P)
        % FILE - Constructs a new File object or array of objects around path strings.
        %
        %   SYNTAX:
        %       F = File(P)
        %
        %   OUTPUT:
        %       F:      FILE
        %               A File object or array of objects that is equivalent in size to the inputted path(s). This
        %               output may then use all of the utility functions associated with this class.
        %
        %   INPUT:
        %       P:      PATH or [ PATHS ] or STRING or { STRING }
        %               A Path object, array of objects, path string, or cell array of path strings pointing to one or
        %               more files. This argument must always refer to a file, defined here as anything with a visible
        %               extension. Folders and files without extensions are not supported and will trigger errors.
            
            if (nargin ~= 0)
                if (isa(P, 'Path'))
                    if (~P(1).IsFile); error('Only paths to files may be converted into a file object.'); end
                    P = P.ToCell();
                end
                
                Path.AssertStringContents(P);
                
                if (~iscell(P)); P = { P }; end
                F(numel(P)) = File;
                for a = 1:numel(P)
                    F(a).ParseFullPath(P{a});
                    if (~F(a).IsFile); error('The path provided must be a reference to a file.'); end
                end
                F = reshape(F, size(P));
            end
        end
        function delete(F)
            % DELETE - Closes any open file references before a File object is destroyed.
            if (F.IsOpen); F.Close(); end    
        end
    end
    
       
    
    %% General Utilities
    methods
        
        function varargout = Load(F, varargin)
        % LOAD - Loads the content of the .MAT file that the File object is pointing to.
        %   
        %   This method imports stored MAT-file variables into the calling function's workspace, very similarly to the
        %   MATLAB-native LOAD function. In fact, LOAD is invoked on every call to this method, and thus much of the
        %   syntax/behavior is carried over and should be familiar. However, there are some subtle differences between
        %   this and the native function.
        %
        %   LOADING SPECIFIC VARIABLES:
        %   Just like the native LOAD function, this method accommodates the loading of a subset of variables stored
        %   inside of the .MAT file. The syntax for invoking this behavior here is identical to that for LOAD; simply
        %   list the name strings of which variables should be imported to the calling workspace. The use of regular
        %   expressions is also supported to achieve this.
        %
        %   However, the order of variable names listed as input arguments here could be important. When multiple
        %   outputs are requested, loaded variables are assigned to output arguments in exactly the same order as they
        %   appear in either the .MAT file (if loading all variables) or in the input argument list (if specifying which
        %   variables to load).
        %
        %   ASSIGNING LOADED VARIABLES DIRECTLY TO THE WORKSPACE:       
        %   If no outputs are requested from this method, then any loaded variables are created and assigned directly in
        %   the calling workspace. This behavior is again identical to that of the native LOAD function when no output
        %   arguments are specified.
        %
        %   OUTPUTTING A SINGLE VARIABLE:
        %   If a single output is requested (e.g. var = F.Load(...)), then the type of the output depends on the number
        %   of variables being loaded from the .MAT file. Specifically, if only one variable is loaded from the .MAT
        %   file, then that loaded value is assigned directly to the output argument. This behavior differs from that of
        %   the native LOAD function, through which loaded variables are always assigned as fields of a structure that
        %   is assigned to the output. 
        %   
        %   When multiple variables are being loaded from a .MAT file, this method resumes behaving like LOAD. In this
        %   case, the single output is a structure and each loaded variable is assigned to it as a field.
        %
        %   OUTPUTTING MULTIPLE VARIABLES:
        %   When multiple outputs are requested, each loaded variable is assigned directly to each listed output
        %   argument; nothing is made into a structure field. Variables are assigned to output arguments in exactly the
        %   same order that they are loaded. When loading entire .MAT files, loading occurs alphabetically by variable
        %   name. However, when the NAME parameter is used, loading occurs in the same order that the names are listed.
        %
        %   If multiple output arguments are used, the number of arguments must correspond exactly with the number of
        %   variables being loaded from the .MAT file. Mismatching numbers of loaded and output variables will result in
        %   an error.
        %
        %   SYNTAX:
        %       F.Load()
        %       F.Load(name1, name2,..., nameN)
        %       var = F.Load(...)
        %       [var1, var2,..., varN] = F.Load(...)
        %
        %   OPTIONAL OUTPUT:
        %       var:    ANYTHING
        %               A single output or array of output variables that can be of any type supported in MATLAB.
        %
        %   INPUT:
        %       F:      FILE
        %               The File object pointing to the .MAT file that is to be loaded.
        %
        %   OPTIONAL INPUT:
        %       name:   STRING
        %               The string variable name(s) that are to be loaded from the .MAT data file. Any number of
        %               variable name strings can be used as separate input arguments to this method so long as they
        %               exactly match the names of variables that exist inside of the .MAT storage file. If no input
        %               arguments are supplied for this method, then all variables in the .MAT file are loaded.
            
            % Fill in or distribute inputs
            if (nargin == 1); vars = {'*'};
            elseif (nargin == 2); vars = varargin(1);
            else vars = varargin; 
            end
            
            % Error check
            F.AssertSingleObject();
            Path.AssertStringContents(vars);
            
            % Load the file contents into a either the caller workspace or a temporary structure
            switch (lower(F.Extension))
                case 'mat'
                    if (nargout == 0)
                        varListStr = repmat('''%s'',', 1, length(vars) - 1);
                        varListStr = [varListStr '''%s'''];
                        varList = sprintf(varListStr, vars{:});
                        evalin('caller', sprintf('load(''%s'', %s);', F.FullPath, varList));
                        return
                    else
                        content = load(F.FullPath, vars{:});
                    end
                    
                otherwise
                    error('Files with extensions %s are not currently loadable through this function.', F.Extension);
            end
            
            % If multiple variables were in the file but only one output is called for, return everything as a structure
            contentFields = fieldnames(content);
            if (nargout == 1 && length(contentFields) > 1)
                varargout{1} = content;
                return
            end
            
            % Otherwise, the number of outputs must match the number of variables loaded
            if (nargout ~= length(contentFields))
                error('The number of outputs must either be one or must match the number of variables being loaded.');
            end
            
            % Distribute file variables to output variables in the same order as they were loaded
            varargout = cell(1, nargout);
            for a = 1:nargout
                varargout{a} = content.(contentFields{a});
            end
            
        end        
        
        % File Stream Management Methods
        function Close(F)
            % CLOSE - Closes an open file reference.
            
            if (~F.IsOpen)
                warning('The file %s is already closed or was never opened. Aborting the operation.', F.Name);
                return;
            end
            
            didClose = fclose(F.FID);
            assert(didClose ~= -1, 'The file %s could not be closed by MATLAB.', F.FullPath);
            
            F.FID = NaN;
            F.IsOpen = false;
        end
        function Edit(F)
            % EDIT - Opens a .m script or function in the MATLAB editor.
            
            if (~strcmpi(F.Extension, 'm'))
                error('Only MATLAB .m files can be opened for editing using this command.');
            end
            edit(F.FullPath);
        end
        function Open(F, opt)
            % OPEN - Opens a file with read or write access.
            
            if (nargin == 1); opt = 'r'; end
            if (F.IsOpen)
                warning('The file %s is already open for editing.', F.Name);
                return;
            end
            
            fid = fopen(F.FullPath, opt);
            assert(fid ~= -1, 'The file %s could not be opened by MATLAB.', F.FullPath);
            
            F.FID = fid;
            F.IsOpen = true;
            F.Permission = opt;
        end
        function Write(F, text, varargin)
            % WRITE - Writes inputted text or data to an open file stream.
            assert(F.IsOpen, 'File %s must first be opened with write access in order to perform a write operation.', F.Name);
            assert(F.Permission ~= 'r', 'File %s was opened with read access only. Writing is not permitted.', F.Name);
            fprintf(F.FID, text, varargin{:});
        end
        function WriteLine(F, text, varargin)
            % WRITELINE - Writes inputted text or data to an open file stream then advances the cursor to the next line.
            F.Write([text '\n'], varargin{:});
        end
        
    end
    
    
end