function u_aggregate_partData(fileStruct, varargin)

%% Initialize
% Assign input variables
inStruct = struct(...
    'filesPath', fileStruct.paths.MAT_files,...
    'searchStr', 'part',...
    'savePath', fileStruct.paths.MAT_files,...
    'saveName', [],...
    'deleteFolder', 0);
assignInputs(inStruct, varargin);

% Get the sorted names of the temporary files
filenames = fileNames(...
    'searchPath', filesPath,...
    'searchStr', searchStr,...
    'fileExt', '.mat',...
    'sortBy', 'date',...
    'sortDirection', 'descend');

% Load the first temporary file
currentData = load(filenames{1});

% Determine if there were more than 1 variables saved to the file
dataTitle = fieldnames(currentData);
if length(dataTitle) > 1    
    % Look for the variable name with data in it
    tempName = regexpi(dataTitle, '\w+data', 'match');
    tempName = [tempName{:}];
    
    % Get rid of nonmatching entries
    for j = 1:length(tempName)
        if isempty(tempName{j})
            tempName(j) = [];
        end
    end
    if length(tempName) ~= 1
        error('Multiple data sets are present')
    end
    dataTitle = tempName{1};
else
    dataTitle = dataTitle{1};
end

% Make sure the data are oriented correctly
if isvector(currentData.(dataTitle))
    currentData.(dataTitle) = reshape(currentData.(dataTitle), [length(currentData.(dataTitle)) 1]);
end

% Get the size of the data array (this should be the same as the size of the full data array)
szData = size(currentData.(dataTitle));

% Initialize the data transfer variable
transData(szData(1), szData(2)) = struct('data', [], 'info', []);

%%  Aggregate the Temporary Data
progressbar('Files Scanned')
i = 1;
try
while i <= length(filenames)
    i = i + 1;
    % Loop through the data to find missing entries
    for j = 1:szData(1)
        for k = 1:szData(2)
            tempFieldnames = fieldnames(currentData.(dataTitle)(j, k));
            tempDataCheck = strcmpi(tempFieldnames, 'data');
            if sum(tempDataCheck) == 1 
                if ~isempty(currentData.(dataTitle)(j, k).data)
                    transData(j, k).data = currentData.(dataTitle)(j, k).data;
                    transData(j, k).info = currentData.(dataTitle)(j, k).info;
                end
            else
                error('Data is not in the standardized format: [*Data(idx).data...]')
            end
        end
    end
    
    % Clear out the temporary data
    clear temp* current*
    
    % Load the next temporary data file to use
    if i > length(filenames)
        progressbar((i-1)/length(filenames))
        break
    else
        currentData = load(filenames{i});
        progressbar((i-1)/length(filenames))
    end
end

% Change transfer variable name to the same as in temporary files
eval([dataTitle '= transData']);

% Save the aggregated file
save([savePath '\' saveName], dataTitle, '-v7.3')

% Delete the temporary files
if deleteFolder
    rmdir(filesPath, 's');
end
catch(err)
    
end

        
        

        
    


