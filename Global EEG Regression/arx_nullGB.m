function arx_nullGB(fileStruct, paramStruct)


%% Initialize
% Assign inputs
assignInputs(paramStruct.xcorr.globSig_BOLD, 'createOnly');
assignInputs(fileStruct.analysis.xcorr.globSig_BOLD, 'createOnly');
totalScans = length(cat(2, scans{:}));

% Create folders for the part files & output file
savePartPath = [fileStruct.paths.MAT_files '\nullPart'];
mkdir(savePartPath);

% Load loop-independent data
load(eegDataFile);

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

% Start MATLAB parallel processing
if matlabpool('size') == 0
    matlabpool
end


%% Cross-Correlate EEG & BOLD Time Courses
progressbar('(DC-GR-EEG)-BOLD Null Distribution Generation')
m = 121;
for i = 121:size(nullPairings, 1)
    % Initialize a data storage array
    nullData(size(nullPairings, 1), 1) = struct('data', [], 'info', []);

    % Get the current null pairing of data
    currentPairing = nullPairings(i, :);
    subScanNums = [indTranslate{currentPairing(1)}; indTranslate{currentPairing(2)}];

    % Load the appropriate BOLD & EEG data
    load(['BOLD_data_subject_' num2str(subScanNums(1, 1)) '.mat']);
    currentBOLD = BOLD_data.BOLD(subScanNums(1, 2)).functional;
    currentGlobSig = eegData(subScanNums(2, 1), subScanNums(2, 2)).data.globalSignal;
    szBOLD = size(currentBOLD);
    

    % Convert time shifts into sample shifts
    shiftsSamples = round(shiftsTime.*eegData(subScanNums(2, 1), subScanNums(2, 2)).info.Fs);
    maxLags = shiftsSamples(end);

    % Pre-allocate the output data structure
    nullData(i).data = zeros([szBOLD(1:(end-1)), length(shiftsSamples)]); 

    % Cross-correlate the data   
    tempNull = zeros([szBOLD(1:3) length(shiftsSamples)]);
    parfor xBOLD = 1:szBOLD(1)
        tempNullY = zeros(size(tempNull(xBOLD, :, :, :)));
        for yBOLD = 1:szBOLD(2)
            tempNullZ = zeros(size(tempNullY(1, yBOLD, :, :)));
            for zBOLD = 1:szBOLD(3)
                % Get the current voxel time course
                currentZ = currentBOLD(xBOLD, yBOLD, zBOLD, :);

                % Cross-correlate the data
                tempNullZ(1, 1, zBOLD, :) = xcorr(currentZ, currentGlobSig, maxLags, 'coeff');
            end
            tempNullY(1, yBOLD, :, :) = tempNullZ;
        end
        tempNull(xBOLD, :, :, :) = tempNullY;
    end
        
    % Store the correlation data
    nullData(i).data = tempNull;

    % Append useful information to the data structure
    nullData(i).info = struct(...
        'structFormat', 'corrData(subject, scan).data.fieldname...',...
        'dataFormat', '(X x Y x Z x Time Shift)',...
        'subject', i,...
        'scans', j,...
        'shiftsTime', shiftsTime,...
        'comments', comments);    
    
    % Save temporary data
    currentPartStr = ['part' num2str(m) '_nullData_globSigEEG-BOLD_' saveID '.mat'];
        m = m + 1;
    save([savePartPath '\' currentPartStr], 'nullData', 'i', 'm', '-v7.3');

    % Garbage collect
    clear current* BOLD_data nullData temp*

    progressbar(i/size(nullPairings, 1)) 
end 

% Save the data
saveStr = ['\nullData_globSigEEG-BOLD_' saveID '.mat'];
u_aggregate_partData(fileStruct,...
    'filesPath', savePartPath,...
    'searchStr', 'part*',...
    'savePath', savePathData,...
    'saveName', saveStr,...
    'deleteFolder', 1);
