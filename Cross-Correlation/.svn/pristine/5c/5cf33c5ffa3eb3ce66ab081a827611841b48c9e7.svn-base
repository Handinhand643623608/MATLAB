function arx_realEB(fileStruct, paramStruct)

%% Initialize
% Assign inputs
assignInputs(paramStruct.xcorr.EEG_BOLD, 'createOnly');
assignInputs(fileStruct.analysis.xcorr.EEG_BOLD, 'createOnly');

% Load loop-independent data
load(eegDataFile);

% Initialize function-specific parameters
maxScans = paramStruct.general.maxScans;
sampleFreqEEG = eegData(1, 1).info.Fs;
shiftsSamples = round(shiftsTime*sampleFreqEEG);
maxLags = shiftsSamples(end);

% Create folders for the part files & output file
savePartPath = [fileStruct.paths.MAT_files '\corrPart'];
mkdir(savePartPath);

% Start MATLAB parallel processing
if matlabpool('size') == 0
    matlabpool
end

%% Cross-Correlate EEG & BOLD Time Courses
progressbar('DC EEG-BOLD Cross-Correlation', 'Scans Completed', 'Electrodes Completed')
m = 1;
for i = subjects

    % Initialize the output data structure
    corrData(length(subjects), maxScans) = struct('data', [], 'info', []);
    
    % Load the BOLD data to be analyzed
    loadStr = [boldDataPath '\BOLD_data_subject_' num2str(i) '.mat'];
    load(loadStr)
    szBOLD = size(BOLD_data.BOLD(1).functional);

    progressbar([], 0, [])
    for j = scans{i}
        % Get the BOLD & EEG data
        currentBOLD = BOLD_data.BOLD(j).functional;

        progressbar([], [], 0)
        for k = 1:length(electrodes)

            % Pre-allocate the output structure
            corrData(i, j).data.(electrodes{k}) = zeros([szBOLD(1:(end-1)), length(shiftsSamples)]);
            
            % Get the EEG data
            currentEEG = eegData(i, j).data.EEG(strcmp(electrodes{k}, eegData(i, j).info.channels), :);

            % Allocate the correlation storage array
            currentCorr = zeros([szBOLD(1:(end-1)) length(shiftsSamples)]);

            % Cross-correlate the modalities
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
                        
            % Store the data in the output structure
            corrData(i, j).data.(electrodes{k}) = currentCorr;                        
                        
            progressbar([], [], k/length(electrodes))
        end

            % Append useful information to the data structure
        corrData(i, j).info = struct(...
            'structFormat', 'corrData(subject, scan).data.fieldname...',...
            'dataFormat', '(X x Y x Z x Time Shift)',...
            'subject', i,...
            'scans', j,...
            'timeShifts', shiftsTime,...
            'electrodes', {electrodes},...
            'comments', comments);

        progressbar([], j/length(scans{i}), [])
    end

    % Save the data part
    currentPartStr = ['part' num2str(m) '_corrData_' electrodes{1} electrodes{2} '-BOLD.mat'];
        m = m + 1;
    save([savePartPath '\' currentPartStr], 'corrData', 'i', 'j', 'm', '-v7.3')

    % Garbage collect
    clear current* BOLD_data corrData

    progressbar(find(subjects == i)/length(subjects), [], []) 
end 

% Aggregate & save the data
saveStr = ['corrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
u_aggregate_partData(fileStruct,...
    'filesPath', savePartPath,...
    'searchStr', 'part*',...
    'savePath', savePathData,...
    'saveName', saveStr,...
    'deleteFolder', 0);


