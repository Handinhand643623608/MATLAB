function ara_corrEB(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.EEG_BOLD, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_BOLD, 'createOnly')
totalScans = length(cat(2, scans{:}));


%% Average Cross-Correlation Data Across All Subjects & Scans
% Load the cross-correlation data
loadStr = ['corrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
load(loadStr)

% Initialize section-specific parameters
szCorr = size(corrData(1, 1).data.(electrodes{1}));

% Initialize the output structure
meanCorrData = struct('data', [], 'info', []);

% Average subjects & scans together
progressbar('Average EEG-BOLD Correlations', 'Subjects Completed', 'Scans Completed')
for i = 1:length(electrodes)        
    progressbar([], 0, [])
    
    % Iniitalize the concatenated correlation transfer array
    currentCatCorr = zeros([szCorr totalScans]);
    
    m = 1;
    for j = subjects
        progressbar([], [], 0)
        for k = scans{j}
            % Concatenate the electrode-specific data with all other subjects & scans
            currentCatCorr(:, :, :, :, m) = corrData(j, k).data.(electrodes{i});
                m = m + 1;
                       
            progressbar([], [], find(scans{j} == k)/length(scans{j}))
        end
        progressbar([], (find(subjects == j)/length(subjects)), [])
    end
    
    % Average together electrode-specific data
    currentMeanCorr = nanmean(currentCatCorr, 5);
    
    % Store results in the output structure
    meanCorrData.data.(electrodes{i}) = currentMeanCorr;    
    
    % Garbage collect
    clear current*
    
    progressbar(i/length(electrodes), [], [])
end

% Fill in information section of output structure
meanCorrData.info = struct(...
    'subjects', subjects,...
    'scans', {scans},...
    'electrodes', {electrodes},...
    'shiftsTime', shiftsTime,...
    'alphaVal', alphaVal,...
    'comments', comments);

% Save the results
saveStr = ['meanCorrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
save([savePathData '\' saveStr], 'meanCorrData', '-v7.3');

% Garbage collect
clear corrData meanCorrData current*

%% Average Cross-Correlation Null Data Across All Pairings
% Load the cross-correlation null data
loadStr = ['nullData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
load(loadStr)

% Initialize section-specific parameters
szNull = size(nullData(1).data.(electrodes{1}));
randOrder = randperm(length(nullData));

% Initialize the output structure
meanNullData = struct('data', [], 'info', []);

progressbar('Average Null EEG-BOLD Correlations', 'Null Groupings Completed', 'Null Scans Completed')
for i = 1:length(electrodes)    
    
    % Initialize electrode-specific transfer array
    currentCatNull = zeros([szNull totalScans]);
    currentCatMeanNull = zeros([szNull floor(length(nullData)/totalScans)]);
    m = 1;
    n = 1;
    
    progressbar([], 0, 0)
    idxProgress = 0;
    for j = randOrder                   
        % Concatenate the electrode-specific null data with all other subjects & scans
        currentCatNull(:, :, :, :, m) = nullData(j).data.(electrodes{i});
            m = m + 1;
                
        % Create groupings of null data the same size as the real data
        if m == totalScans
            currentMeanNull = nanmean(currentCatNull, 5);
            currentCatMeanNull(:, :, :, :, n) = currentMeanNull;
                n = n + 1;
                m = 1;
            currentCatNull = zeros([szNull totalScans]);
            idxProgress = (idxProgress + 1)/(length(nullData)/totalScans);
            progressbar([], idxProgress, []);
        end
        progressbar([], [], j/length(nullData))
    end
    
    % Store the results in the output structure
    meanNullData.data.(electrodes{i}) = currentCatMeanNull;
    
    % Garbage collect
    clear current*
    
    progressbar(i/length(electrodes), [], [])
end

% Fill in information section of output structure
meanNullData.info = struct(...
    'electrodes', {electrodes},...
    'shiftsTime', shiftsTime,...
    'alphaVal', alphaVal,...
    'comments', comments);

% Save the results
saveStr = ['meanNullData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
save([savePathData '\' saveStr], 'meanNullData', '-v7.3');

% Garbage collect
clear nullData meanNullData current*
            
            
            
        
        