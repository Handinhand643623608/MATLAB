function arx_nullEG(fileStruct, paramStruct)

%% Initialize
% Initialize parameters
assignInputs(fileStruct.analysis.xcorr.EEG_Global, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_Global, 'createOnly')

% Load the data to be used
load(eegDataFile);

% Initialize function-specific parameters
totalScans = length(cat(2, scans{:}));
sampleFreqEEG = eegData(1, 1).info.Fs;

% Determine the time shifts to use in terms of samples
shiftsSamples = round(shiftsTime*sampleFreqEEG);
maxLags = shiftsSamples(end);

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

% Initialize the null data storage structure
nullData(size(nullPairings, 1), 1) = struct('data', [], 'info', []);

% MATLAB parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool;
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end


%% Cross-Correlate Data for the Null Distribution
progressbar('EEG-IC Null Distribution Generation')
for i = 1:size(nullPairings, 1)

    % Get the current null pairing of data
    currentPairing = nullPairings(i, :);
    subScanNums = [indTranslate{currentPairing(1)}; indTranslate{currentPairing(2)}];

    % Acquire the EEG data to be paired
    currentEEG = eegData(subScanNums(1, 1), subScanNums(1, 2)).data.EEG;
    currentEEG = double(currentEEG);

    % Acquire the RSN time course to be paired
    load(['BOLD_data_subject_' num2str(subScanNums(2, 1)) '.mat']);
    currentGlobSig = BOLD_data.BOLD(subScanNums(2, 2)).globSig;
    currentGlobSig = double(currentGlobSig);
    currentGlobSig = zscore(currentGlobSig);

    % Allocate the output results array
    currentNull = zeros(size(currentEEG, 1), length(shiftsSamples));

    % Cross-correlate the data
    switch parallelSwitch
        case true
            parfor k = 1:size(currentEEG, 1)
                currentChannel = currentEEG(k, :);
                currentChannel = zscore(currentChannel);
                currentNull(k, :) = xcorr(currentGlobSig, currentChannel, maxLags, 'coeff');
            end

        otherwise        
            for k = 1:size(currentEEG, 1)
                currentChannel = currentEEG(k, :);
                currentChannel = zscore(currentChannel);
                currentNull(k, :) = xcorr(currentGlobSig, currentChannel, maxLags, 'coeff');
            end
    end

    % Fill in the data section of the output structure
    nullData(i).data = currentNull;

    % Fill in the information section of output structure
    nullData(i).info = struct(...
        'nullPairing', {{[subScanNums(1, :)] [subScanNums(2, :)]}},...
        'dataFormat', '(Channels x Time Shifts)',...
        'shiftsTime', [shiftsTime],...
        'channels', {eegData(subScanNums(1, 1), subScanNums(1, 2)).info.channels},...
        'comments', comments);

    % Garbage collect
    clear current* BOLD_data

progressbar(i/size(nullPairings, 1))
end

% Save the results
saveStr = [savePathData '\nullData_' saveTag '_EEG-Global_' saveID '.mat'];
save(saveStr, 'nullData', '-v7.3')

% Garbage collect
clear eegData BOLD_data

        
    

