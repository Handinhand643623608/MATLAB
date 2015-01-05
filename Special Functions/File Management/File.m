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
%		20141215:	Implemented the method Clone, which overloads the same Path method, for creating deep copies of file
%					object arrays.
%		20141217:	Added some documentation to the WHICH static method. Implemented a new static method GETEXTENSION
%					for getting the string extension parts of file names.
    


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
        %       P:      PATH or [ PATHS ] or STRING or { STRINGS }
        %               A Path object, array of objects, path string, or cell array of path strings pointing to one or
        %               more files. This argument must always refer to a file, defined here as anything with a visible
        %               extension. Folders and files without extensions are not supported and will trigger errors.
            
            if (nargin ~= 0 && ~isempty(P))
                if (isa(P, 'Path'))
                    assert(P(1).IsFile, 'Only paths to files may be converted into a file object.');
                    P = P.ToCell();
                end
                
                Path.AssertStringContents(P);
                
                if (~iscell(P)); P = { P }; end
                F(numel(P)) = File;
                for a = 1:numel(P)
                    F(a).ParseFullPath(P{a});
                    assert(F(a).IsFile, 'The path provided must be a reference to a file.');
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
        
		function C = Clone(F)
		% CLONE - Creates deep copies of inputted file objects.
		%
		%	CLONE performs a deep copy process on FILE objects, meaning that although the output is identical to the
		%	input, the two do not contain any common object references. This is important when programming by reference
		%	in order to avoid unintentionally changing properties across class instances.
		%
		%	SYNTAX:
		%		C = F.Clone()
		%		C = Clone(F)
		%
		%	OUTPUT:
		%		F:		FILE or [ FILES ]
		%				An identical clone of the file(s) in F. Properties of this output that contain objects do not
		%				reference the same objects as the corresponding properties in F.
		%
		%	INPUT:
		%		F:		FILE or [ FILES ]
		%				A file object or array of objects that are to be copied.
			C = Clone@Path(F);
			C = File(C);
		end
		
        % File Stream Management Methods
        function Close(F)
        % CLOSE - Closes an open file stream.
        %
        %   This method closes any open data streams for files, producing a warning for any files that were not opened
        %   using the OPEN method of this class. 
        %
        %   Data streams should always be closed manually as soon as any IO operations on the file are completed. This
        %   is because open streams lock the underlying file and prevent access from any other part of the computer
        %   system. Additionally, so long as a stream is open, the possibility of file corruption is increased.
        %
        %   The File class offers additional protection against forgetting to close file streams by providing a
        %   destructor method that performs the close operation automatically whenever objects are deleted from memory.
        %   Thus, whenever an open File object goes out of scope, the stream is automatically closed. However, this
        %   should not be used as a substitute for manually closing the stream because, so long as the object is
        %   referenced in the base or active workspace, it will not be deleted. 
        %
        %   SYNTAX:
        %       Close(F)
        %       F.Close()
        %
        %   INPUT:
        %       F:      FILE or [ FILES ]
        %               A File object or array of objects with open data streams to be closed.
        %               
            
            for a = 1:numel(F)
                if (~F(a).IsOpen)
                    warning('The file %s is already closed or was never opened. Aborting the operation.', F(a).FullName);
                    return;
                end

                didClose = fclose(F(a).FID);
                assert(didClose ~= -1, 'The file %s could not be closed by MATLAB.', F(a).FullPath);

                F(a).FID = NaN;
                F(a).IsOpen = false;
            end
        end
        function Edit(F)
        % EDIT - Opens a .m script or function in the MATLAB editor.
        %
        %   This method opens any MATLAB code or text file with the .m extension. The contents of this file are
        %   irrelevant to invoking this method, so it may contain plain text or function/script/class definitions.
        %
        %   EDIT is just a wrapper for the MATLAB-native function EDIT. As such, it inherits most of the behaviors that
        %   are supported by that function. Unlike the native EDIT function, this method does not support the opening of
        %   multiple file references, nor does it support invocation with an empty File object (the equivalent of
        %   calling the native EDIT with no inputs).
        %
        %   SYNTAX:
        %       Edit(F)
        %       F.Edit()
        %
        %   INPUT:
        %       F:      FILE
        %               A single File object referencing a MATLAB .m code file. This file must be a .m text file;
        %               inputting a reference to any other file type is an error. Arrays of File objects are not
        %               supported by this function.
        %
        %   See also:   EDIT
            F.AssertSingleObject();
            assert(strcmpi(F.Extension, 'm'), 'Only MATLAB .m files can be opened for editing using this command.');
            edit(F.FullPath);
        end
        function Open(F, opt)
        % OPEN - Opens a file with read or write access.
        %
        %   This method opens a data stream for a file that exists or will be created on the computer's hard drive. The
        %   file in question does not have to exist prior to invoking this method; it will be created automatically in 
        %   the parent directory referenced by F if it does not.
        %
        %   OPEN is just a wrapper for the MATLAB-native function FOPEN. As such, it inherits most of the behaviors that
        %   are supported by that function. Unlike FOPEN, OPEN returns no values because the handle to the data stream
        %   is managed automatically by the File object. For more information on file IO operations, see the MATLAB
        %   documentation for FOPEN and the associated functions.
        %
        %   SYNTAX:
        %       Open(F)
        %       Open(F, opt)
        %       F.Open()
        %       F.Open(opt)
        %
        %   INPUT:
        %       F:      FILE
        %               A File object pointing to a file on the computer's hard drive. This file does not have to exist
        %               prior to using this method. If it does not, the file is created upon opening.
        %
        %   OPTIONAL INPUT:
        %       opt:    STRING
        %               A string indicating the read/write access that the resulting data stream should have. This
        %               argument can be any of the permission strings supported by the native function FOPEN.
        %
        %   See also:   CLOSE, FCLOSE, FOPEN, WRITE, WRITELINE
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
        %
        %   This method writes text to a file's open data stream so that it appears in the file upon opening it using
        %   MATLAB or any other text editor. The file being used must already exist and must have been opened with write
        %   permissions using the OPEN method. If any of these criteria are failed, WRITE will throw an error.
        %
        %   WRITE is just a wrapper for the MATLAB-native function FPRINFT. As such, it inherits most of the behaviors
        %   that are supported by that function. Unlike FPRINTF, this function does not require a handle to the data
        %   stream (i.e. FID in the documentation for FPRINTF) because this handle is managed automatically by File
        %   objects. Additionally, there is currently no output from WRITE. For more information on file IO operations,
        %   see the MATLAB documentation for FPRINTF and the associated functions.
        %
        %   SYNTAX:
        %       Write(F, text)
        %       Write(F, text, var1, var2,..., varN)
        %       F.Write(text)
        %       F.Write(text, var1, var2,..., varN)
        %
        %   INPUT:
        %       F:          FILE
        %                   A single File object that is to have data written to it. Arrays of objects are not supported
        %                   by this function. This file must have been opened using the OPEN method of this class and
        %                   must have write permission. Failing any of these criteria is an error.
        %
        %       text:       STRING
        %                   A single string that will be written to the open file. Arrays and cell arrays of strings are
        %                   not supported by this function. This string may be any length of characters and can contain
        %                   escape sequences (i.e. formatting characters) that will be substituted with values from any
        %                   var parameters.
        %
        %   OPTIONAL INPUTS:
        %       var:        ANYTHING
        %                   A comma-separated list of variables whose values will be substituted into the text argument
        %                   wherever escape sequences are found. An unlimited number of variables may be supplied, so
        %                   long as there are an equivalent number of escape sequences and these values are given in the
        %                   same order as the escapes are found in the string. By default, no variables will be used and
        %                   the text argument will be printed as a string literal. 
        %
        %   See also:   FPRINTF, SPRINTF
            assert(nargin >= 2 && ~isempty(text) && ischar(text), 'A single non-empty string of text must be provided for a write operation.');
            assert(F.IsOpen, 'File %s must first be opened with write access in order to perform a write operation.', F.Name);
            assert(F.Permission ~= 'r', 'File %s was opened with read access only. Writing is not permitted.', F.Name);
            Path.AssertSingleString(text);
            fprintf(F.FID, text, varargin{:});
        end
        function WriteLine(F, text, varargin)
        % WRITELINE - Writes inputted text or data to an open file stream then advances the cursor to the next line.
        %
        %   This method writes a line of text to a file's open data stream so that it appears in the file upon opening
        %   it using MATLAB or any other text editor. The file being used must already exist and must have been opened
        %   with write permissions using the OPEN method. If any of these criteria are failed, WRITELINE will throw an
        %   error.
        %
        %   WRITELINE is just a wrapper for the File class method WRITE. As such, it inherits most of the behaviors that
        %   are supported by that function. Unlike WRITE, this method does not require a string of text as an input
        %   because it appends a new-line character to whatever string (empty by default) is being used. That string is
        %   then given to the WRITE method, which performs the write operation, and passes the checks for empty strings.
        %
        %   SYNTAX:
        %       WriteLine(F)
        %       WriteLine(F, text)
        %       WriteLine(F, text, var1, var2,..., varN)
        %       F.WriteLine()
        %       F.WriteLine(text)
        %       F.WriteLine(text, var1, var2,..., varN)
        %
        %   INPUT:
        %       F:          FILE
        %                   A single File object that is to have a line of text written to it. Arrays of objects are not
        %                   supported by this function. This file must have been opened using the OPEN method of this
        %                   class and must have write permission. Failing any of these criteria is an error.
        %
        %   OPTIONAL INPUT:
        %       text:       STRING
        %                   A single string that will be written to the open file. Arrays and cell arrays of strings are
        %                   not supported by this function. This string may be any length of characters and can contain
        %                   escape sequences (i.e. formatting characters) that will be substituted with values from any
        %                   var parameters.
        %                   DEFAULT: ''
        %
        %       var:        ANYTHING
        %                   A comma-separated list of variables whose values will be substituted into the text argument
        %                   wherever escape sequences are found. An unlimited number of variables may be supplied, so
        %                   long as there are an equivalent number of escape sequences and these values are given in the
        %                   same order as the escapes are found in the string. By default, no variables will be used and
        %                   the text argument will be printed as a string literal. 
        %                   DEFAULT: []
            if nargin == 1; text = ''; end
            Path.AssertSingleString(text)
            F.Write([text '\n'], varargin{:});
        end
        
    end
    
    methods (Static)
        function ext = GetExtension(fileName)
		% GETEXTENSION - Gets the extension part of an inputted file name string.
		%
		%	SYNTAX:
		%		ext = File.GetExtension(fileName)
		%
		%	OUTPUT:
		%		ext:		STRING
		%					The string extension part of the FILENAME input argument. This string will always include
		%					the dot ('.') part of the extension. If no extension is found on the file name, this method
		%					returns an empty string.
		%
		%	INPUT:
		%		fileName:	STRING
		%					The string name of a file.
			assert(ischar(fileName), 'File names must be specified as string type arguments.');
			[~, ~, ext] = fileparts(fileName);
		end
		function F = Which(fileName)
        % WHICH - Creates a FILE object referencing a file that is on MATLAB's active search path.
		%
		%	WHICH searches the MATLAB active directories for a file whose name matches the input argument FILENAME. If a
		%	match is found, this method automatically constructs and returns a fully resolved FILE object referencing
		%	it. If multiple identically named files are on the MATLAB working path, this function returns a FILE object
		%	referencing only the first match found.
		%
		%	WHICH is useful for resolving MATLAB functions or files whose exact locations on the computer are unknown.
		%	Other than returning a FILE object instead of a path string, this method performs exactly the same function
		%	as the MATLAB-native WHICH
		%
		%	SYNTAX:
		%		F = File.Which(fileName)
		%
		%	OUTPUT:
		%		F:				FILE
		%						A fully resolved FILE object that references a file whose name is identical to the
		%						inputted FILENAME string. If no files matching that string are found, then an empty FILE
		%						object is returned.
		%
		%	INPUT:
		%		fileName:		STRING
		%						A string containing the name of the function or file being searched for.
		%
		%	See also: WHICH
			f = which(fileName);
			if isempty(f); F = File;
			else F = File(f); end
		end
    end
    
    
    %% Overloaded MATLAB Methods
    methods
        function display(F)
        % DISPLAY - Displays information about the File object in the console window.
        %
        %   This method organizes and formats File object information before displaying it in the console window. The
        %   information that is displayed is different depending on the number of objects that are inputted. For
        %   singleton objects, this function prints a more detailed view of the File instance that includes several 
        %   properties of the instance. For arrays of File objects, this function prints a list of file names only.
        %
        %   DISPLAY is called automatically whenever operations returning a File object are invoked without using the
        %   semicolon output suppressor. This includes the act of invoking an existing object in a function, script, or
        %   in the console (i.e. by typing F and pressing enter if "F" is the name of a File object).
        %
        %   SYNTAX:
        %       display(F)
        %       F.display()
        %
        %   INPUT:
        %       F:      FILE or [ FILES ]
        %               A File object or array of objects for which information will be displayed in the MATLAB console.
        %
        %   See also:   DISP, DISPLAY, FPRINTF
            if (numel(F) == 1)
                fprintf(1,...
                   ['\n',...
                    '%s File Reference:\n\n',...
                    '\tFile Name:\t\t%s\n\n',...
                    '\t   Exists:\t\t%s\n',...
                    '\tExtension:\t\t%s\n',...
                    '\t   IsOpen:\t\t%s\n',...
                    '\t Location:\t\t%s\n\n'],...
                    upper(F.Extension),...
                    F.FullName,...
                    Path.BooleanString(F.Exists),...
                    F.Extension,...
                    Path.BooleanString(F.IsOpen),...
                    F.ParentDirectory.ToString());
            else
                nameCell = cell(numel(F), 1);
                for a = 1:numel(F); nameCell{a} = F(a).FullName; end
                formatStr = [repmat('\t%s\n', 1, numel(F)) '\n'];
                fprintf(1,...
                    ['\n',...
                     '(%d x %d) Array of File References:\n\n',...
                     formatStr],...
                     size(F, 1),...
                     size(F, 2),...
                     nameCell{:});
            end
        end
    end
    
    
    
end