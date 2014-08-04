function arb_corrEB(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.EEG_BOLD, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_BOLD, 'createOnly')

% Load the data
disp('Loading Data')
loadMeanStr = ['meanCorrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
loadNullStr = ['meanNullData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
load(loadMeanStr)
load(loadNullStr)
disp('Data Loaded')

% Load the MNI grey matter mask
maskGM = load_nii([fileStruct.paths.segments '\grey.nii']);
maskGM = maskGM.img;

% MATLAB parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end


%% Bootstrap the Data
progressbar('DC EEG-BOLD Bootstrapping');
for i = 1:length(electrodes)    
    % Get the electrode-specific cross-correlation data
    currentCorr = meanCorrData.data.(electrodes{i});
    currentNull = meanNullData.data.(electrodes{i});
        
    % Apply a grey matter mask to the data
    currentCorr = u_mask_data(currentCorr, maskGM, 0.7);
    currentNull = u_mask_data(currentNull, maskGM, 0.7);
    
    % Bootstrap & store the thresholds
    disp('Begin Bootstrapping Data')
    [lowerCutoff upperCutoff] = u_bootstrap_corrData(currentCorr, currentNull, alphaVal);
    disp(['Data for ' electrodes{i} '-BOLD Correlation Thresholded'])
    meanCorrData.info.cutoffs.(electrodes{i}) = [lowerCutoff upperCutoff];

    progressbar(i/length(electrodes))
end

% Save the results
saveStr = ['meanCorrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
save([savePathData '\' saveStr], 'meanCorrData', '-v7.3');
