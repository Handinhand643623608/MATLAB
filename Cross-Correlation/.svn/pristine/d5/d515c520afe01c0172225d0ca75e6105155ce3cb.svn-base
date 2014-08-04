function f_CA_run_xcorr_nullBI(fileStruct, paramStruct)

%% Initialize
% Load the data to be used
load blpData_alpha
load timeCourses_RSN

% Initialize function-specific parameters
if isempty(paramStruct.xcorr.BLP_IC.alpha.subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.xcorr.BLP_IC.alpha.subjects;
    scans = paramStruct.xcorr.BLP_IC.alpha.scans;
end
shiftsTime = paramStruct.xcorr.BLP_IC.alpha.timeShifts;
sampleFreqBLP = BLP_data(1, 1).info.Fs;
components = timeCourses(1, 1).info.componentIdents;
totalScans = paramStruct.general.totalScans;

% Determine the time shifts to use in terms of samples
shiftsSamples = shiftsTime*sampleFreqBLP;

% Initialize the null data storage structure
nullData(totalScans, 1) = struct('data', [], 'info', []);

% Determine the null distribution pairing sequence
indTranslate = cell(totalScans, 1);
m = 1;
for i = subjects
    for j = scans{i}
        indTranslate{m} = [i j];
        m = m + 1;
    end
end

nullPairings = nchoosek(1:totalScans, 2);

%% Cross-Correlate Data for the Null Distribution
progressStr = ['Alpha BLP-IC Null Distribution Generation'];
progressbar(progressStr, 'Components Finished')
for i = 1:size(nullPairings, 1)
    progressbar([], 0)
    for j = 1:length(components)

        % Get the current null pairing of data
        currentPairing = nullPairings(i, :);
        subScanNums = [indTranslate{currentPairing(1)}; indTranslate{currentPairing(2)}];

        % Acquire the BLP data to be paired
        currentBLP = BLP_data(subScanNums(1, 1), subScanNums(1, 2)).data.BLP;
        currentBLP = double(currentBLP);

        % Acquire the RSN time course to be paired
        currentTimeCourse = timeCourses(subScanNums(2, 1), subScanNums(2, 2)).data.(components{j});
        currentTimeCourse = double(currentTimeCourse);
        currentTimeCourse = zscore(currentTimeCourse);
        currentTimeCourse = currentTimeCourse';
        
        % Allocate the output results array
        currentNull = zeros(size(currentBLP, 1), (2*shiftsSamples + 1));
        
        % Cross-correlate the data
        for k = 1:size(currentBLP, 1)
            currentChannel = currentBLP(k, :);
            currentChannel = zscore(currentChannel);
            currentNull(k, :) = xcorr(currentChannel, currentTimeCourse, shiftsSamples, paramStruct.xcorr.BLP_IC.alpha.corrType);
        end
        
        % Fill in the data section of the output structure
        nullData(i).data.(components{j}) = currentNull;
        
        % Fill in the information section of output structure
        nullData(i).info = struct(...
            'nullPairing', {{[subScanNums(1, :)] [subScanNums(2, :)]}},...
            'dataFormat', '(Channels x Time Shifts)',...
            'componentIdents', {components},...
            'corrType', paramStruct.xcorr.BLP_IC.alpha.corrType,...
            'timeShifts', [-shiftsTime:(1/sampleFreqBLP):shiftsTime],...
            'origData', 'Downsampled, Filtered BLP & RSN Time Courses',...
            'channels', {BLP_data(subScanNums(1, 1), subScanNums(1, 2)).info.channels});
        
        % Garbage collect
        clear current*
  
        progressbar([], j/length(components))
    end
    progressbar(i/size(nullPairings, 1), [])
end

% Save the results
saveStr = [fileStruct.paths.MAT_files '\xcorr\nullData_BLP_IC_alpha.mat'];
save(saveStr, 'nullData', '-v7.3')

% Garbage collect
clear BLP_data timeCourses

        
    

