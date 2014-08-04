function ara_corrEG(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.Global_Global, 'createOnly')
assignInputs(paramStruct.xcorr.Global_Global, 'createOnly')
totalScans = length(cat(2, scans{:}));

%% Average Cross-Correlation Data Across Time Shifts for Subjects & Scans
% Load the cross-correlation data
loadStr = ['corrData_Global-Global_' saveID];
load(loadStr);

% Initialize the output structure
meanCorrData = struct('data', [], 'info', []);

% Initialize the concatenated data array
currentCatCorr = [];

for i = subjects
    for j = scans{i}            
        % Get the current subject & scan correlation data
        currentCorr = corrData(i, j).data;
        if ~isrow(currentCorr)
            currentCorr = currentCorr';
        end

        % Concatenate the data
        currentCatCorr = cat(1, currentCatCorr, currentCorr);            
    end
end

% Average together the data & store results
currentMeanCorr = nanmean(currentCatCorr, 1);
currentMeanSE = nanstd(currentCatCorr, [], 1);
meanCorrData.mean = currentMeanCorr;
meanCorrData.std = currentMeanSE;

% Garbage collect
clear current*

% Fill in the information section of the output structure
meanCorrData.info = struct(...
    'subjects', subjects,...
    'scans', {scans},...
    'shiftsTime', corrData(1, 1).info.shiftsTime,...
    'comments', comments);
    
% Save the results
saveStr = [savePathData '\meanCorrData_Global-Global_' saveID '.mat'];
save(saveStr, 'meanCorrData', '-v7.3')

% Garbage collect
clear corrData meanCorrData        
