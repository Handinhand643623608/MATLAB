function f_CA_run_xcorr_realBI(fileStruct, paramStruct)

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

% Determine the time shifts to use in terms of samples
shiftsSamples = shiftsTime*sampleFreqBLP;

% Initialize the correlation data arrays
corrData(length(subjects), paramStruct.general.maxScans) = struct('data', [], 'info', []);

%% Cross-Correlate BLP & IC Time Courses
progressStr = ['Alpha BLP-IC Cross-Correlation Generation'];
progressbar(progressStr, 'Scans Finished', 'ICs Finished')
for i = subjects
    progressbar([], 0, [])
    for j = scans{i}
        progressbar([], [], 0)
        for k = 1:length(components)
            
            % Acquire the current subject & scan BLP data
            currentBLP = BLP_data(i, j).data.BLP;
            currentBLP = double(currentBLP);
            
            % Acquire the current RSN time course
            currentTimeCourse = timeCourses(i, j).data.(components{k});
            currentTimeCourse = double(currentTimeCourse);
            currentTimeCourse = zscore(currentTimeCourse);
            currentTimeCourse = currentTimeCourse';
            
            % Allocate a temporary results array
            currentCorr = zeros(size(currentBLP, 1), (2*shiftsSamples + 1));
            
            % Cross-correlate the data
            for L = 1:size(currentBLP, 1)
                currentChannel = currentBLP(L, :);
                currentChannel = zscore(currentChannel);
                currentCorr(L, :) = xcorr(currentChannel, currentTimeCourse, shiftsSamples, paramStruct.xcorr.BLP_IC.alpha.corrType);
            end
            
            % Fill in the data section of output structure
            corrData(i, j).data.(components{k}) = currentCorr;
            
            % Fill in the information section of output structure
            corrData(i, j).info = struct(...
                'subject', i,...
                'scan', j,...
                'dataFormat', '(Channels x Time Shifts)',...
                'componentIdents', {components},...
                'corrType', paramStruct.xcorr.BLP_IC.alpha.corrType,...
                'timeShifts', [-shiftsTime:(1/sampleFreqBLP):shiftsTime],...
                'origData', 'Downsampled, Filtered BLP & RSN Time Courses',...
                'channels', {BLP_data(i, j).info.channels});
                
            % Garbage collect
            clear current*
            
            % Update the progress bar
            progressbar([], [], k/length(components))
        end
        progressbar([], j/length(scans{i}), [])
    end
    progressbar(i/length(subjects), [], [])
end

% Save the results
saveStr = [fileStruct.paths.MAT_files '\xcorr\corrData_BLP_IC_alpha.mat'];
save(saveStr, 'corrData', '-v7.3')

% Garbage collect
clear BLP_data timeCourses
            