function arb_corrEG(fileStruct, paramStruct)

%% Initialize
% Initialize parameters
assignInputs(fileStruct.analysis.xcorr.EEG_Global, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_Global, 'createOnly')

% Load the data
corrLoadStr = ['meanCorrData_' saveTag '_EEG-Global_' saveID '.mat'];
nullLoadStr = ['meanNullData_' saveTag '_EEG-Global_' saveID '.mat'];
load(corrLoadStr)
load(nullLoadStr)


%% Bootstrap the Data
progressbar('EEG-IC Bootstrapping')
% Get the network-specific cross-correlation data
currentCorr = meanCorrData.data;
currentNull = meanNullData.data;

% Bootstrap & store the thresholds
[lowerCutoff, upperCutoff] = u_bootstrap_corrData(currentCorr, currentNull, alphaVal);
meanCorrData.info.cutoffs = [lowerCutoff upperCutoff];


% Save the results
saveStr = [savePathData '\meanCorrData_' saveTag '_EEG-Global_' saveID '.mat'];
save(saveStr, 'meanCorrData', '-v7.3')