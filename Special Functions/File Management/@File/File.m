classdef File < Path
    
%% CHANGELOG
%   Written by Josh Grooms on 20141010
    


    %% Properties
    
    
    
    
    %% Constructor Method
    methods
        function F = File(P)
            % FILE - Constructs a new File object or array of objects around path strings.
            
            if (nargin ~= 0)
                if (isa(P, 'Path'))
                    if (~P(1).IsFile); error('Only paths to files may be converted into a file object.'); end
                    pathStrs = cell(size(P));
                    for a = 1:numel(P); pathStrs{a} = P(a).FullPath; end
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
    end
    
       
    
    %% General Utilities
    methods
        
        function varargout = Load(F, varargin)
            % LOAD - Loads the content of the file that the object is pointing to.
            
            % Fill in or distribute inputs
            if (nargin == 1); vars = {'*'};
            elseif (nargin == 2); vars = varargin(1);
            else vars = varargin; 
            end
            
            % Error check
            F.AssertSingleObject();
            Path.AssertStringContents(vars);
            
            % Load the file contents into a temporary structure
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
        
        function Edit(F)
            % EDIT - Opens a MATLAB .m script or function for editing.
            if (~strcmpi(F.Extension, 'm'))
                error('Only MATLAB .m files can be opened for editing using this command.');
            end
            edit(F.FullPath);
        end
        
    end
    
    
end