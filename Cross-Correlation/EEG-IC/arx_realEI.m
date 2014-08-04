function arx_realEI(fileStruct, paramStruct)

%% Initialize
% Initialize parameters
assignInputs(fileStruct.analysis.xcorr.EEG_IC, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_IC, 'createOnly')

% Load the data to be used
load(eegDataFile);
load(icDataFile);

% Initialize function-specific parameters
maxScans = paramStruct.general.maxScans;
sampleFreqEEG = eegData(1, 1).info.Fs;
components = timeCourses(1, 1).info.componentIdents;

% Determine the time shifts to use in terms of samples
shiftsSamples = round(shiftsTime*sampleFreqEEG);
maxLags = shiftsSamples(end);

% Initialize the correlation data arrays
corrData(length(subjects), maxScans) = struct('data', [], 'info', []);

% MATLAB parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool;
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end


%% Cross-Correlate EEG & IC Time Courses
progressbar('EEG-IC Cross-Correlation Generation', 'Scans Finished', 'ICs Finished')
for i = subjects
    progressbar([], 0, [])
    for j = scans{i}
        progressbar([], [], 0)
        for k = 1:length(components)
            
            % Acquire the current subject & scan EEG data
            currentEEG = eegData(i, j).data.EEG;
            currentEEG = double(currentEEG);
            
            % Acquire the current RSN time course
            currentTimeCourse = timeCourses(i, j).data.(components{k});
            currentTimeCourse = double(currentTimeCourse);
            currentTimeCourse = zscore(currentTimeCourse);
            currentTimeCourse = currentTimeCourse';
            
            % Allocate a temporary results array
            currentCorr = zeros(size(currentEEG, 1), length(shiftsSamples));
            
            % Cross-correlate the data
            switch parallelSwitch
                case true
                    parfor L = 1:size(currentEEG, 1)
                        currentChannel = currentEEG(L, :);
                        currentChannel = zscore(currentChannel);
                        currentCorr(L, :) = xcorr(currentTimeCourse, currentChannel, maxLags, 'coeff');
                    end
                    
                otherwise
                    for L = 1:size(currentEEG, 1)
                        currentChannel = currentEEG(L, :);
                        currentChannel = zscore(currentChannel);
                        currentCorr(L, :) = xcorr(currentTimeCourse, currentChannel, maxLags, 'coeff');
                    end
            end
            
            % Fill in the data section of output structure
            corrData(i, j).data.(components{k}) = currentCorr;
            
            % Fill in the information section of output structure
            corrData(i, j).info = struct(...
                'subject', i,...
                'scan', j,...
                'dataFormat', '(Channels x Time Shifts)',...
                'componentIdents', {components},...
                'shiftsTime', [shiftsTime],...
                'channels', {eegData(i, j).info.channels},...
                'comments', comments);
                
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
saveStr = [savePathData '\corrData_EEG_IC_' saveTag '_' saveID '.mat'];
save(saveStr, 'corrData', '-v7.3')

% Garbage collect
clear eegData timeCourses
            