classdef (Sealed) Archive < dynamicprops
    
    
    
    
    properties (SetAccess = private)
        
        SourceFile
        
    end
    
    
    %% Constructor Method
    methods
        function archive = Archive(fileName)
            %ARCHIVE - 
            
            if nargin ~= 0                
                % Error out if the .mat file doesn't already exist
                if ~exist(fileName, 'file')
                    error('A pre-existing .mat file must already exist to create a partial storage object out of it.');
                end
                
                % Get the variables stored within the .mat file
                vars = whos('-file', fileName);
                for a = 1:length(vars)
                    archive.addprop(vars(a).name);
                end
                
            end
        end
    end
    
    
    
    %%
    methods (Hidden)
        
        function output = subsref(archive, idxStruct)
            
            
            if ~strcmpi(idxStruct(1).type, '.')
                error('Variables inside of archives must be indexed using dot notation');
            end
            
            var = idxStruct(1).subs;
            
            
            varInfo = whos('-file', archive.SourceFile, var);
            
            
            if length(idxStruct) == 1; output = load(archive.SourceFile, var, '-mat');
            else
                
                for a = 1:length(idxStruct)
                    
                    idxData = idxStruct(a).subs;
                    
                    numDataDims = length(idxData);
                    
                    
                    
                    while b <= length(idxData)
                        
                        
                        
                        
                    end
                    
                    
                    
                    for b = length(idxData):-1:1
                    
                        numericVectorCheck = isnumeric(idxData{b}) && isvector(idxData{b});
                        
                        if numericVectorCheck 
                            
                            
                            
                            
                        
                    end
                    
                end
            end
            
            

                    
                    
        end
        
    end
    
    
    
    %%
    methods (Static, Access = private)
        
        function ToSubset(idxStruct, varInfo)
            
            % Allow only one indexing structure at a time to be read
            if numel(idxStruct) > 1; error('One structure at a time please.'); end
            
            % Get the subscripts for the current level of indexing
            idxData = idxStruct.subs;
            
            % Use the subscripts to determine data dimensions
            numDims = length(idxData);
            
            % Initialize 
            idxDataRange = cell(1, numDims);
            
            
            for a = 1:numDims
                
                
                % Get the indices requested along the current data dimension
                idxCurrent = idxData{a};
                
                
                currentTriplet = ones(1, 3);
                
                % Translate the requested indices into a 3-element range [MIN, STRIDE, MAX]
                if strmcpi(idxCurrent, ':')
                    
                    currentTriplet = [1, 1, varInfo.size(a)];
                else
                    
                    currentTriplet = [min(idxCurrent)
                    
                end
                
            end
            
            
            
        end
        
    end
end