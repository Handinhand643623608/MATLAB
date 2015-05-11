% FILE - A class that manages and provides utilities for Path objects that point to files instead of directories.
%
%	File Properties:
%		Exists			- Gets a Boolean indicating whether or not the file or folder exists on the computer.
%		Extension		- Gets the extension string of the file, without the '.' character.
%		FullName		- Gets a string containing the full name of a file, including its extension.
%		FullPath		- Gets the full path string referencing the file.
%		IsOpen			- Gets a Boolean indicating whether or not a data stream has been opened for the file.
%		Name			- Gets a string containing the name of the file or folder that the Path object points to.
%		ParentDirectory - Gets a Folder object for the directory immediately above the currently stored reference.
%		ParentDrive		- Gets a Folder object for the drive letter of the stored reference (for Windows PCs only).
%
%	File Constructors:
%		File			- Constructs a new File object from a path string.
%		Which			- Creates a File object referencing a file that is on MATLAB's active search path.
%
%	File Methods:
%		Clone			- Creates a deep copy of a File object.
%		Close			- Closes an open file stream.
%		CopyTo			- Copies one or more files to a new location on the computer.
%		Edit			- Opens a .m script or function in the MATLAB editor.
%		Load			- Loads the content of a .MAT file to which the File object points.
%		Open			- Opens a new file stream with read or write access.
%		NavigateTo		- Changes the MATLAB working directory to the parent directory of the file.
%		Sort			- Sorts a list of files into specific categories.
%		ToCell			- Converts a File object array into a cell array of full path strings.
%		ToString
%		View			- Opens the parent directory of a file in Windows Explorer.
%		Write			- Writes inputted text or data to an open file stream.
%		WriteLine		- Writes inputted text or data to an open file stream then advances the cursor to the next line.
%
%	File Overloads:
%		cd				- Changes the MATLAB working directory to the parent folder of the file.
%		exist			- Determines whether or not the file exists on the computer at the specified location.

%% CHANGELOG
%   Written by Josh Grooms on 20141010
%		20141215:	Implemented the method Clone, which overloads the same Path method, for creating deep copies of file
%					object arrays.
%		20141217:	Added some documentation to the WHICH static method. Implemented a new static method GETEXTENSION
%					for getting the string extension parts of file names.
%       20150208:   Implemented a method to search for particular files among an array of file objects. Implemented a method
%					to sort file arrays into a category structure using an arbitrary number of search queries.
%		20150224:	Implemented a method for reading in all text from a file as a single string.
%		20150511:	Overhauled the class documentation to summarize all of the properties and methods that are available.
%					Updated this class for compatibility with changes to other file management objects.



%% CLASS DEFINITION
classdef File < Path

    


    %% DATA
	properties (Dependent)
		FullName		% Gets a string containing the full name of a file, including its extension.
		FullPath		% Gets the full path string referencing the file.
	end
	
	properties (SetAccess = protected)
		Extension		% Gets the extension string of the file, without the '.' character.
		IsOpen			% Gets a Boolean indicating whether or not a data stream has been opened for the file.
	end
    
    properties (Access = private)
        FID				% The numeric handle to an open data stream for the file this object contains.
        Permission      % The string read/write permission that was used to open the file's data stream.
	end
    
    
    
	%% PROPERTIES
	methods
		function n = get.FullName(F)
			n = [F.Name '.' F.Extension];
		end
		function p = get.FullPath(F)
			p = [F.Directory '/' F.Name '.' F.Extension];
		end
	end
	
	
	
    %% CONSTRUCTOR & DESTRUCTOR
    methods
        function F = File(p)
        % FILE - Constructs a new File object from a path string.
        %
        %   SYNTAX:
        %       F = File(P)
        %
        %   OUTPUT:
        %       F:      FILE
        %               A File object referencing the file stored at the location in P. 
        %
        %   INPUT:
        %       P:      STRING
		%				A path string pointing to a file located on the computer.
        %
		%	See also: FILE.WHICH, PATH.RESOLVE, WHICH, WHERE
            if (nargin == 0); p = ''; end
			F = F@Path(p);
		
			F.IsOpen = false;
			F.FID = NaN;
			F.Permission = '';
        end
        function delete(F)
            % DELETE - Closes any open file references before a File object is destroyed.
            if (F.IsOpen); F.Close(); end    
        end
	end
    
	methods (Static)
		function F = Which(fileName)
        % WHICH - Creates a File object referencing a file that is on MATLAB's active search path.
		%
		%	WHICH searches the MATLAB active directories for a file whose name matches the input argument FILENAME. If a
		%	match is found, this method automatically constructs and returns a fully resolved FILE object referencing it. If
		%	multiple identically named files are on the MATLAB working path, this function returns a FILE object referencing
		%	only the first match found.
		%
		%	WHICH is useful for resolving MATLAB functions or files whose exact locations on the computer are unknown. Other
		%	than returning a FILE object instead of a path string, this method performs exactly the same function as the
		%	MATLAB-native WHICH
		%
		%	SYNTAX:
		%		F = File.Which(fileName)
		%
		%	OUTPUT:
		%		F:				FILE
		%						A fully resolved FILE object that references a file whose name is identical to the inputted
		%						FILENAME string. If no files matching that string are found, then an empty FILE object is
		%						returned.
		%
		%	INPUT:
		%		fileName:		STRING
		%						A string containing the name of the function or file being searched for.
		%
		%	See also: FILE.FILE, PATH.RESOLVE, WHICH, WHERE
			f = which(fileName);
			if isempty(f); F = File();
			else F = File(f); end
		end
	end
       
    
	
    %% UTILITIES
	methods (Access = protected)
		function ParseFullPath(F, s)
		% PARSEFULLPATH - Deconstructs a full path string and populates the Path object properties with it.
            
            F.AssertSingleObject();
            Path.AssertSingleString(s);
            
            [p, n, e] = fileparts(s);
            F.Directory = Path.FormatPathString(p);
            F.Name = n;
            F.Extension = Path.FormatExtensionString(e);
            
            if (ispc)
                drivePattern = '^([^\\/]:).*';
                driveLetter = regexp(F.Directory, drivePattern, 'tokens');
                F.Drive = driveLetter{1}{1};
            else
                F.Drive = '/';
            end
		end
	end
	
	methods (Static)
		function e = GetExtension(fileName)
		% GETEXTENSION - Gets the extension part of an inputted file name string.
		%
		%	SYNTAX:
		%		e = File.GetExtension(fileName)
		%
		%	OUTPUT:
		%		e:			STRING
		%					The string extension part of the FILENAME input argument. This string will always include
		%					the dot ('.') part of the extension. If no extension is found on the file name, this method
		%					returns an empty string.
		%
		%	INPUT:
		%		fileName:	STRING
		%					The string name of a file.
			assert(ischar(fileName), 'File names must be specified as string type arguments.');
			[~, ~, e] = fileparts(fileName);
		end
	end
	
    methods
        
        function varargout = Load(F, varargin)
        % LOAD - Loads the content of a .MAT file that the File object is pointing to.
        %   
        %   This method imports stored MAT-file variables into the calling function's workspace, very similarly to the
        %   MATLAB-native LOAD function. In fact, LOAD is invoked on every call to this method, and thus much of the
        %   syntax/behavior is carried over and should be familiar. However, there are some subtle differences between this
        %   and the native function.
        %
        %   LOADING SPECIFIC VARIABLES:
        %		Just like the native LOAD function, this method accommodates the loading of a subset of variables stored
        %		inside of the .MAT file. The syntax for invoking this behavior here is identical to that for LOAD; simply
        %		list the name strings of which variables should be imported to the calling workspace. The use of regular
        %		expressions is also supported to achieve this.
        %
        %		However, the order of variable names listed as input arguments here could be important. When multiple outputs
        %		are requested, loaded variables are assigned to output arguments in exactly the same order as they appear in
        %		either the .MAT file (if loading all variables) or in the input argument list (if specifying which variables
        %		to load).
        %
        %   ASSIGNING LOADED VARIABLES DIRECTLY TO THE WORKSPACE:       
        %		If no outputs are requested from this method, then any loaded variables are created and assigned directly in
        %		the calling workspace. This behavior is again identical to that of the native LOAD function when no output
        %		arguments are specified.
        %
        %   OUTPUTTING A SINGLE VARIABLE:
        %		If a single output is requested (e.g. var = F.Load(...)), then the type of the output depends on the number
        %		of variables being loaded from the .MAT file. Specifically, if only one variable is loaded from the .MAT
        %		file, then that loaded value is assigned directly to the output argument. This behavior differs from that of
        %		the native LOAD function, through which loaded variables are always assigned as fields of a structure that is
        %		assigned to the output.
        %   
        %		When multiple variables are being loaded from a .MAT file, this method resumes behaving like LOAD. In this
        %		case, the single output is a structure and each loaded variable is assigned to it as a field.
        %
        %   OUTPUTTING MULTIPLE VARIABLES:
        %		When multiple outputs are requested, each loaded variable is assigned directly to each listed output
        %		argument; nothing is made into a structure field. Variables are assigned to output arguments in exactly the
        %		same order that they are loaded. When loading entire .MAT files, loading occurs alphabetically by variable
        %		name. However, when the NAME parameter is used, loading occurs in the same order that the names are listed.
        %
        %		If multiple output arguments are used, the number of arguments must correspond exactly with the number of
        %		variables being loaded from the .MAT file. Mismatching numbers of loaded and output variables will result in
        %		an error.
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
        %               The string variable name(s) that are to be loaded from the .MAT data file. Any number of variable
        %               name strings can be used as separate input arguments to this method so long as they exactly match the
        %               names of variables that exist inside of the .MAT storage file. If no input arguments are supplied for
        %               this method, then all variables in the .MAT file are loaded.
		%
		%	See also: LOAD
            
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
        function [R, ids] = Search(F, query)
        % SEARCH - Searches for specific files among an array of file objects using a string query.
        %
        %   SYNTAX:
        %       R = F.Search(query)
        %       [R, ids] = F.Search(query)
        %   
        %   OUTPUTS:
        %       R:          [ FILES ]
        %                   An array of results whose names match the inputted query.
        %
        %       ids:        [ BOOLEANS ]
        %                   The indices of the matched files from the original file object array F.
        %
        %   INPUT:
        %       F:          [ FILES ]
        %                   An array of file objects to be searched.
        %
        %       query:      string
        %                   A query string used to identify and isolate the results in R. Searching is performed using
        %                   regular expressions, and so this argument may contain metacharacters.
            c = F.ToCell();
            ids = regexp(c, query, 'start');
            ids = ~(cellfun(@isempty, ids));
            R = F(ids);
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
		function s = Sort(F, varargin)
		% SORT - Sorts a list of files into specific categories.
		%
		%	SYNTAX:
		%		s = F.Sort(categories)
		%		s = F.Sort(category1, category2,...)
		%
		%	OUTPUT:
		%		s:				STRUCT
		%						A structure whose fields are named after the values in the CATEGORIES argument. Each field
		%						contains a list of files whose names contain the category name.
		%
		%	INPUT:
		%		F:				[ FILES ]
		%						An array of file objects to be categorized.
		%
		%		categories:		STRING or { STRINGS }
		%						A cell array or comma-separated list of strings containing category names. Each of these will
		%						become a QUERY argument for the SEARCH method as well as a field name in the outputted
		%						structure. In other words, the file object array will be searched for each name in this list
		%						and any matches found will be placed in the correspondingly named field of S.
		%
		%	See also: FILE.SEARCH
	
			s = emptystruct(varargin{:});
			cats = fieldnames(s);
			
			for a = 1:length(cats)
				s.(cats{a}) = F.Search(cats{a});
			end
		end
		function s = ReadAllText(F)
		% READALLTEXT - Reads all text from a file, automatically managing the opening and closing process. 
			F.AssertSingleObject();
			s = fileread(F.ToString());
		end
		
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
    
    
    
end