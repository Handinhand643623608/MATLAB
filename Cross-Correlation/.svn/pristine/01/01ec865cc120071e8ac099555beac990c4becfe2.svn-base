function f_CA_run_average_xcorrDataBI(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
if isempty(paramStruct.xcorr.BLP_IC.alpha.subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.xcorr.BLP_IC.alpha.subjects;
    scans = paramStruct.xcorr.BLP_IC.alpha.scans;
end
totalScans = paramStruct.general.totalScans;

%% Average Cross-Correlation Data Across Time Shifts for Subjects & Scans
% Load the cross-correlation data
load corrData_BLP_IC_alpha

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
            currentCorr = u_CA_standardize_EEG(currentCorr, corrData(j, k).info.channels, paramStruct);
            sizeCorr = size(currentCorr);
            
            % Concatenate the data
            currentCatCorr = cat((length(sizeCorr) + 1), currentCatCorr, currentCorr);            
        end
    end
    
    % Average together the data
    currentMeanCorr = nanmean(currentCatCorr, (length(sizeCorr) + 1));
    
    % Store the data in the output structure
    meanCorrData.data.(components{i}) = currentMeanCorr;

    % Garbage collect
    clear current*
end

% Fill in the information section of the output structure
meanCorrData.info = struct(...
    'subjects', subjects,...
    'scans', {scans},...
    'channels', {paramStruct.general.channels},...
    'componentIdents', {components},...
    'timeShifts', corrData(1, 1).info.timeShifts);
    
% Save the results
saveStr = [fileStruct.paths.MAT_files '\xcorr\meanCorrData_BLP_IC_alpha.mat'];
save(saveStr, 'meanCorrData', '-v7.3')

% Garbage collect
clear corrData

%% Average Cross-Correlation Null Data Across Time Shifts for Subjects & Scans
% Load the null data
load nullData_BLP_IC_alpha

% Initialize the output structure
meanNullData = struct('data', [], 'info', []);

% Concatenate & average all data across time shifts
for i = 1:length(components)
    % Initialize the concatenated data array
    currentCatNull = [];
    currentCatMeanNull = [];
    
    for j = 1:length(nullData)
        % Get the current network-specific null data & EEG channel names
        currentNull = nullData(j).data.(components{i});
        currentChannels = nullData(j).info.channels;
        
        % Standardize the number of channels in data for averaging
        currentNull = u_CA_standardize_EEG(currentNull, currentChannels, paramStruct);
        sizeNull = size(currentNull);
        
        % Concatenate the data
        currentCatNull = cat((length(sizeNull) + 1), currentCatNull, currentNull);
        
        % Create groupings of null data the same size as the real data
        if size(currentCatNull, (length(sizeNull) + 1)) == totalScans
            currentMeanNull = nanmean(currentCatNull, (length(sizeNull) + 1));
            currentCatMeanNull = cat((length(size(currentMeanNull)) + 1), currentCatMeanNull, currentMeanNull);
            currentCatNull = [];
        end
    end
    
    % Store the results
    meanNullData.data.(components{i}) = currentMeanNull;

    % Garbage collect
    clear current*
end

% Fill in information section of output structure
meanNullData.info = struct(...
    'channels', {paramStruct.general.channels},...
    'componentIdents', {components},...
    'timeShifts', [nullData(1).info.timeShifts]);

% Save the results
saveStr = [fileStruct.paths.MAT_files '\xcorr\meanNullData_BLP_IC_alpha.mat'];
save(saveStr, 'meanNullData', '-v7.3')

% Garbage collect
clear nullData


        
