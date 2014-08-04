function arx_nullEB(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.EEG_BOLD, 'createOnly');
assignInputs(paramStruct.xcorr.EEG_BOLD, 'createOnly');
totalScans = length(cat(2, scans{:}));

% Create folders for the part files & output file
savePartPath = [fileStruct.paths.MAT_files '\nullPart'];
mkdir(savePartPath);

% Load data stored elsewhere
load(eegDataFile)
sampleFreqEEG = eegData(1, 1).info.Fs;
shiftsSamples = round(shiftsTime*sampleFreqEEG);
maxLags = shiftsSamples(end);

% Determine the null pairing sequence
indTranslate = cell(totalScans, 1);
m = 1;
for i = subjects
    for j = scans{i}
        indTranslate{m} = [i j];
        m = m + 1;
    end
end
nullPairings = nchoosek(1:totalScans, 2);

% Initialize MATLAB parallel processing
if matlabpool('size') == 0
    matlabpool
end    

%% Cross-Correlate Data for the Null Distribution
m = 1;
progressbar('DC EEG-BOLD Null Distribution Generation', 'Electrodes Completed')
for i = 1:size(nullPairings, 1)
    % Initialize a data storage array
    nullData(size(nullPairings, 1), 1) = struct('data', [], 'info', []);
    
    % Get the current null pairing of data
    currentPairing = nullPairings(i, :);
    subScanNums = [indTranslate{currentPairing(1)}; indTranslate{currentPairing(2)}];
    
    % Load the appropriate BOLD data
    load(['BOLD_data_subject_' num2str(subScanNums(1, 1)) '.mat']);
    currentBOLD = BOLD_data.BOLD(subScanNums(1, 2)).functional;
    szBOLD = size(currentBOLD);

    progressbar([], 0)
    for j = 1:length(electrodes)     
        % Acquire the EEG data
        currentEEG = eegData(subScanNums(2, 1), subScanNums(2, 2)).data.EEG;
        currentEEG = currentEEG(strcmp(electrodes{j}, eegData(subScanNums(2, 1), subScanNums(2, 2)).info.channels), :);
        if length(currentEEG) ~= szBOLD(4)
            currentEEG((szBOLD(4) + 1):end) = [];
        end
                
        % Allocate the correlation storage array
        currentCorr = zeros([szBOLD(1:(end-1)) length(shiftsSamples)]);
        
        % Cross-corelate the modalities
        parfor xBOLD = 1:szBOLD(1)
            tempCorrY = zeros(size(currentCorr(xBOLD, :, :, :)));
            for yBOLD = 1:szBOLD(2)
                tempCorrZ = zeros(size(tempCorrY(1, yBOLD, :, :)));
                for zBOLD = 1:szBOLD(3)
                    currentZ = currentBOLD(xBOLD, yBOLD, zBOLD, :);
                    tempCorrZ(1, 1, zBOLD, :) = xcorr(currentZ, currentEEG, maxLags, 'coeff');
                end
                tempCorrY(1, yBOLD, :, :) = tempCorrZ;
            end
            currentCorr(xBOLD, :, :, :) = tempCorrY;
        end
        
        % Store the results in the output data structure
        nullData(i).data.(electrodes{j}) = currentCorr;
        
        progressbar([], j/length(electrodes))
    end
    
    % Fill in the information section of output structure
    nullData(i).info = struct(...
        'nullPairing', {{[subScanNums(1, :)] [subScanNums(2, :)]}},...
        'dataFormat', '(X x Y x Z x timeShifts)',...
        'electrodes', {electrodes},...
        'shiftsTime', shiftsTime,...
        'comments', comments);
    
    % Save temporary data
    currentPartStr = ['part' num2str(m) '_nullData_' electrodes{1} electrodes{2} '-BOLD.mat'];
        m = m + 1;
    save([savePartPath '\' currentPartStr], 'nullData', 'i', 'm', '-v7.3');
    
    % Garbage collect
    clear current* BOLD_data nullData
    
    progressbar(i/size(nullPairings, 1), [])
end

matlabpool('close')

% Aggregate & save the data
saveStr = ['nullData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
u_aggregate_partData(fileStruct,...
    'filesPath', savePartPath,...
    'searchStr', 'part*',...
    'savePath', savePathData,...
    'saveName', saveStr,...
    'deleteFolder', 1);