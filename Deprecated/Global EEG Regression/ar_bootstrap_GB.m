function ar_bootstrap_GB(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(paramStruct.xcorr.globSig_BOLD, 'createOnly');
assignInputs(fileStruct.analysis.xcorr.globSig_BOLD, 'createOnly');

% Load the data
disp('Loading Data')
loadMeanStr = ['meanCorrData_globSigEEG-BOLD_' saveID '.mat'];
loadNullStr = ['meanNullData_globSigEEG-BOLD_' saveID '.mat'];
load(loadMeanStr)
load(loadNullStr)
disp('Data Loaded')

% Load the MNI grey matter mask
maskGM = load_nii([fileStruct.paths.segments '\grey.nii']);
maskGM = maskGM.img;

% Mask the null data
currentCorr = u_mask_data(meanCorrData.data, maskGM, 0.7);
currentNull = u_mask_data(meanNullData.data, maskGM, 0.7);

% Parallel p-value generation
if parallelPVals && matlabpool('size') == 0
    matlabpool
elseif ~parallelPVals && matlabpool('size') ~= 0
    matlabpool close
end

% Garbage collect
clear catNullData


%% Bootstrap the Data
disp('Begin Bootstrapping Data')
[lowerCutoff upperCutoff] = u_bootstrap_corrData(currentCorr, currentNull, alphaVal);
disp('Data for Global Signal EEG-BOLD Correlation Thresholded')
meanCorrData.info.cutoffs = [lowerCutoff upperCutoff];

% Store the data with the thresholds
saveStr = [savePathData '\meanCorrData_globSigEEG-BOLD_' saveID '.mat'];
save(saveStr, 'meanCorrData', '-v7.3');


