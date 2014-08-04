function memorizeData(dataSet1, dataSet2, varargin)




inStruct = struct(...
    'MemType', 'RAM',...
    'UseMemory', 'half');

% Flatten the data, but preserve the last dimension (usually time)
if ismatrix(dataSet1)
    dataSet1 = reshape(dataSet1, [], size(dataSet1, ndims(dataSet1)));
    dataSet2 = reshape(dataSet2, [], size(dataSet2, ndims(dataSet2)));
end

% Determine which type of memory to preserve
switch lower(MemType)
    case {'ram', 'system', 'memory'}
        % Get the available system memory (in bytes)
        szMemory = memory; szMemory = memory.MaxPossibleArrayBytes;
        
        
    case {'gpu', 'graphics'}
        % Get the available GPU memory (in bytes)
        szMemory = gpuDevice; szMemory = szMemory.FreeMemory;
end
        
% Determine the numeric type of the data & how much can fit into memory
switch class(dataSet1)
    case 'double'
        maxNumelData = szMemory/8;
    case 'single'
        maxNumelData = szMemory/4;
end



[maxRow, maxCol] = ind2sub(size(dataSet1), maxNumelData);


