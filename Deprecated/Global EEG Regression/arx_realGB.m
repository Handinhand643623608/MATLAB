function arx_realGB(fileStruct, paramStruct)


%% Initialize
% Assign inputs
assignInputs(paramStruct.xcorr.globSig_BOLD, 'createOnly');
assignInputs(fileStruct.analysis.xcorr.globSig_BOLD, 'createOnly');

% Create folders for the part files & output file
savePartPath = [fileStruct.paths.MAT_files '\corrPart'];
mkdir(savePartPath);

% Load loop-independent data
load(eegDataFile);

% Initialize function-specific parameters
maxScans = paramStruct.general.maxScans;

% Start MATLAB parallel processing
if matlabpool('size') == 0
    matlabpool
end


%% Cross-Correlate EEG & BOLD Time Courses
progressbar('(DC-GR-EEG)-BOLD Cross-Correlation', 'Scans Completed')
m = 1;
for i = subjects
    % Initialize the output data structure
    corrData(length(subjects), maxScans) = struct('data', [], 'info', []);
    
    % Load the BOLD data to be analyzed
    loadStr = [boldDataPath '\BOLD_data_subject_' num2str(i) '.mat'];
    load(loadStr)
    szBOLD = size(BOLD_data.BOLD(1).functional);

    progressbar([], 0)
    for j = scans{i}        
        % Convert time shifts into sample shifts
        shiftsSamples = round(shiftsTime.*eegData(i, j).info.Fs);
        maxLags = shiftsSamples(end);
        
        % Pre-allocate the data structure
        corrData(i, j).data = zeros([szBOLD(1:3) length(shiftsSamples)]);

        % Get the BOLD & global signal data
        currentBOLD = BOLD_data.BOLD(j).functional;
        currentGlobSig = eegData(i, j).data.globalSignal;  
        
        % Cross-correlate the data
        tempCorr = zeros([szBOLD(1:3) length(shiftsSamples)]);
        parfor xBOLD = 1:szBOLD(1)
%             currentX = currentBOLD(xBOLD, :, :, :);
            tempCorrY = zeros(size(tempCorr(xBOLD, :, :, :)));
            for yBOLD = 1:szBOLD(2)
%                 currentY = currentX(1, yBOLD, :, :);
                tempCorrZ = zeros(size(tempCorrY(1, yBOLD, :, :)));
                for zBOLD = 1:szBOLD(3)
                    % Get the current voxel time course
                    currentZ = currentBOLD(xBOLD, yBOLD, zBOLD, :);
                    
                    % Cross-correlate the data
                    tempCorrZ(1, 1, zBOLD, :) = xcorr(currentZ, currentGlobSig, maxLags, 'coeff');
                end
                tempCorrY(1, yBOLD, :, :) = tempCorrZ;
            end
            tempCorr(xBOLD, :, :, :) = tempCorrY;
        end
        
        % Store the correlation data
        corrData(i, j).data = tempCorr;
        
        % Append useful information to the data structure
        corrData(i, j).info = struct(...
            'structFormat', 'corrData(subject, scan).data.fieldname...',...
            'dataFormat', '(X x Y x Z x Time Shift)',...
            'subject', i,...
            'scans', j,...
            'shiftsTime', shiftsTime,...
            'comments', comments);    
        
        progressbar([], j/length(scans{i}))
    end
    
    % Save the data part
    currentPartStr = ['part' num2str(m) '_corrData_globSigEEG-BOLD_' saveID '.mat'];
        m = m + 1;
    save([savePartPath '\' currentPartStr], 'corrData', 'i', 'm', '-v7.3')
    
    % Garbage collect
    clear current* BOLD_data corrData temp*

    progressbar(find(subjects == i)/length(subjects), []) 
end 

% Aggregate & save the data
saveStr = ['corrData_globSigEEG-BOLD_' saveID '.mat'];
u_aggregate_partData(fileStruct,...
    'filesPath', savePartPath,...
    'searchStr', 'part*',...
    'savePath', savePathData,...
    'saveName', saveStr,...
    'deleteFolders', 1);

