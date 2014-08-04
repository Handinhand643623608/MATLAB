function arx_realEG(fileStruct, paramStruct)

%% Initialize
% Assign inputs
assignInputs(paramStruct.xcorr.EEG_Global, 'createOnly');
assignInputs(fileStruct.analysis.xcorr.EEG_Global, 'createOnly');

% Load loop-independent data
load(eegDataFile);

% Initialize function-specific parameters
maxScans = paramStruct.general.maxScans;
sampleFreqEEG = eegData(1, 1).info.Fs;
shiftsSamples = round(shiftsTime*sampleFreqEEG);
maxLags = shiftsSamples(end);

% Initialize the output data structure
corrData(length(subjects), maxScans) = struct('data', [], 'info', []);

% Start MATLAB parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end


%% Cross-Correlate EEG & BOLD Time Courses
progressbar('DC EEG-BOLD Cross-Correlation', 'Scans Completed')
for i = subjects
    
    % Load the BOLD data to be analyzed
    loadStr = [boldDataPath '\BOLD_data_subject_' num2str(i) '.mat'];
    load(loadStr)

    progressbar([], 0)
    for j = scans{i}
        % Get the BOLD & EEG data
        currentGlobSig = BOLD_data.BOLD(j).globSig;
        currentGlobSig = double(currentGlobSig);
        currentGlobSig = zscore(currentGlobSig);
        currentEEG = eegData(i, j).data.EEG;
        currentEEG = double(currentEEG);
        
        % Allocate the correlation storage array
        currentCorr = zeros(size(currentEEG, 1), length(shiftsSamples));

        % Cross-correlate the data
        switch parallelSwitch
            case true
                parfor L = 1:size(currentEEG, 1)
                    currentChannel = currentEEG(L, :);
                    currentChannel = zscore(currentChannel);
                    currentCorr(L, :) = xcorr(currentGlobSig, currentChannel, maxLags, 'coeff');
                end

            otherwise
                for L = 1:size(currentEEG, 1)
                    currentChannel = currentEEG(L, :);
                    currentChannel = zscore(currentChannel);
                    currentCorr(L, :) = xcorr(currentGlobSig, currentChannel, maxLags, 'coeff');
                end
        end


        % Store the data in the output structure
        corrData(i, j).data = currentCorr;

        progressbar([], j/length(scans{i}))


        % Append useful information to the data structure
        corrData(i, j).info = struct(...
            'structFormat', 'corrData(subject, scan).data...',...
            'dataFormat', '(Channels x Time Shift)',...
            'subject', i,...
            'scans', j,...
            'shiftsTime', shiftsTime,...
            'channels', {eegData(i, j).info.channels},...
            'comments', comments);

    end
    
    % Garbage collect
    clear current* BOLD_data

    progressbar(find(subjects == i)/length(subjects), []) 
end



% Aggregate & save the data
saveStr = [savePathData '\corrData_' saveTag '_EEG-Global_' saveID '.mat'];
save(saveStr, 'corrData', '-v7.3')

% Garbage collect
clear eegData timeCourses


