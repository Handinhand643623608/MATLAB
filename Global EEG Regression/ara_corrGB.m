function ara_corrGB(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.globSig_BOLD, 'createOnly')
assignInputs(paramStruct.xcorr.globSig_BOLD, 'createOnly')
totalScans = length(cat(2, scans{:}));


%% Average Cross-Correlation Data Across All Subjects & Scans
% Load the cross-correlation data
loadStr = ['corrData_globSigEEG-BOLD_' saveID '.mat'];
load(loadStr)

% Initialize section-specific parameters
szNull = size(corrData(1, 1).data);
currentCatCorr = zeros([szNull totalScans]);
m = 1;

% Initialize the correlation data output structure
meanCorrData = struct('data', [], 'info', []);

% Average subjects & scans together
progressbar('Average Global Signal-BOLD Correlations', 'Scans Completed')
for i = subjects
    progressbar([], 0)
    for j = scans{i}
        % Get the current electrode correlation data & size of array
        currentCatCorr(:, :, :, :, m) = corrData(i, j).data;
            m = m + 1;        

        progressbar([], find(scans{i} == j)/length(scans{i}))
    end
    progressbar((find(subjects == i)/length(subjects)), [])
end

% Average together electrode-specific data
currentMeanCorr = nanmean(currentCatCorr, (length(szNull) + 1));

% Store results in the output structure
meanCorrData.data = currentMeanCorr;    

% Garbage collect
clear current*

% Fill in information section of output structure
meanCorrData.info = struct(...
    'subjects', subjects,...
    'scans', {scans},...
    'shiftsTime', corrData(1, 1).info.shiftsTime,...
    'comments', comments);

% Save the results
currentSaveStr = [savePathData '\meanCorrData_globSigEEG-BOLD_' saveID '.mat'];
save(currentSaveStr, 'meanCorrData', '-v7.3');

% Garbage collect
clear corrData meanCorrData current*


%% Average Cross-Correlation Null Data Across All Pairings
% Load the cross-correlation null data
loadStr = ['nullData_globSigEEG-BOLD_' saveID '.mat'];
load(loadStr)

% Initialize section-specific parameters
szNull = size(nullData(1, 1).data);
currentCatNull = zeros([szNull totalScans]);
currentCatMeanNull = zeros([szNull floor(length(nullData)/totalScans)]);
idxProgress = 0;
m = 1;
n = 1;

% Initialize the null data output structure
meanNullData = struct('data', [], 'info', []);

% Randomize the ordering for null data averaging
randOrder = randperm(length(nullData));

% Initialize section-specific parameters
progressbar('Average Null EEG-BOLD Correlations', 'Null Scans Completed')
for i = randOrder           
    % Concatenate the null data
    currentCatNull(:, :, :, :, m) = nullData(i).data;
        m = m + 1;

    % Create groupings of null data the same size as the real data
    if m == totalScans
        % Average the group of null data
        currentMeanNull = nanmean(currentCatNull, (length(szNull) + 1));
        
        % Concatenate the mean group of null data with other means
        currentCatMeanNull(:, :, :, :, n) = currentMeanNull;
            n = n + 1;
            m = 1;
        currentCatNull = zeros([szNull totalScans]);
        idxProgress = (idxProgress + 1)/(length(nullData)/totalScans);
        progressbar(idxProgress, []);
    end
    progressbar([], find(randOrder == i)/length(nullData))
end
    
% Store the results in the output structure
meanNullData.data = currentCatMeanNull;

% Garbage collect
clear current*

% Fill in information section of output structure
meanNullData.info = struct(...
    'shiftsTime', nullData(1, 1).info.shiftsTime,...
    'comments', comments);

% Save the results
saveStr = [savePathData '\meanNullData_globSigEEG-BOLD_' saveID '.mat'];
save(saveStr, 'meanNullData', '-v7.3');

% Garbage collect
clear nullData meanNullData current*
            
            
            
        
        