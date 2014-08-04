function ara_corrEI(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.EEG_IC, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_IC, 'createOnly')
totalScans = length(cat(2, scans{:}));
allChannels = paramStruct.general.channels;

%% Average Cross-Correlation Data Across Time Shifts for Subjects & Scans
% Load the cross-correlation data
loadStr = ['corrData_EEG_IC_' saveTag '_' saveID];
load(loadStr);

% Initialize section-specific parameters
components = corrData(1, 1).info.componentIdents;

% Initialize the output structure
meanCorrData = struct('data', [], 'info', []);

% Concatenate & average all subjects & scans across time shifts
for i = 1:length(components)    
    % Initialize the concatenated data array
    currentCatCorr = [];
    
    for j = subjects
        for k = scans{j}            
            % Get the current subject & scan correlation data
            currentCorr = corrData(j, k).data.(components{i});
                        
            % Standardize the number of channels in data for averaging
            currentCorr = u_standardize_EEG(currentCorr, corrData(j, k).info.channels, paramStruct);
            sizeCorr = size(currentCorr);
            
            % Concatenate the data
            currentCatCorr = cat((length(sizeCorr) + 1), currentCatCorr, currentCorr);            
        end
    end
    
    % Average together the data & store results
    currentMeanCorr = nanmean(currentCatCorr, (length(sizeCorr) + 1));
    meanCorrData.data.(components{i}) = currentMeanCorr;

    % Garbage collect
    clear current*
end

% Fill in the information section of the output structure
meanCorrData.info = struct(...
    'subjects', subjects,...
    'scans', {scans},...
    'channels', {allChannels},...
    'componentIdents', {components},...
    'shiftsTime', corrData(1, 1).info.shiftsTime,...
    'comments', comments);
    
% Save the results
saveStr = [savePathData '\meanCorrData_EEG_IC_' saveTag '_' saveID '.mat'];
save(saveStr, 'meanCorrData', '-v7.3')

% Garbage collect
clear corrData

%% Average Cross-Correlation Null Data Across Time Shifts for Subjects & Scans
% Load the null data
nullLoadStr = ['nullData_EEG_IC_' saveTag '_' saveID '.mat'];
load(nullLoadStr);

% Concatenate & average all data across time shifts   
for i = 1:length(components)
    % Initialize the concatenated data array
    currentCatNull = zeros([length(allChannels), length(shiftsTime), totalScans]);
    currentCatMeanNull = zeros([length(allChannels), length(shiftsTime), floor(length(nullData)/totalScans)]);

    m = 1;
    n = 1;
    for j = 1:length(nullData)
        % Get the current network-specific null data & EEG channel names
        currentNull = nullData(j).data.(components{i});
        currentChannels = nullData(j).info.channels;

        % Standardize the number of channels in data for averaging
        currentCatNull(:, :, m) = u_standardize_EEG(currentNull, currentChannels, paramStruct);
            m = m + 1;
        
        % Create groupings of null data the same size as the real data
        if m == totalScans
            currentCatMeanNull(:, :, n) = nanmean(currentCatNull, 3);
                m = 1;
                n = n + 1;
            currentCatNull = zeros([length(allChannels), length(shiftsTime), totalScans]);
        end
    end
    
    % Store the results
    meanNullData.data.(components{i}) = currentCatMeanNull;
   
    % Garbage collect
    clear current*
end

% Fill in the information section of output structure
meanNullData.info = struct(...
    'channels', {allChannels},...
    'componentIdents', {components},...
    'shiftsTime', nullData(1).info.shiftsTime,...
    'comments', comments);

% Save the results
saveStr = [savePathData '\meanNullData_EEG_IC_' saveTag '_' saveID '.mat'];
save(saveStr, 'meanNullData', '-v7.3')

% Garbage collect
clear nullData


        
