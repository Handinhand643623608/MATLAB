function arb_corrEI(fileStruct, paramStruct)

%% Initialize
% Initialize parameters
assignInputs(fileStruct.analysis.xcorr.EEG_IC, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_IC, 'createOnly')

% Load the data
corrLoadStr = ['meanCorrData_EEG_IC_' saveTag '_' saveID '.mat'];
nullLoadStr = ['meanNullData_EEG_IC_' saveTag '_' saveID '.mat'];
load(corrLoadStr)
load(nullLoadStr)

% Initialize function-specific parameters
components = meanCorrData.info.componentIdents;


%% Bootstrap the Data
progressbar('EEG-IC Bootstrapping')
for i = 1:length(components)
    % Get the network-specific cross-correlation data
    currentCorr = meanCorrData.data.(components{i});
    currentNull = meanNullData.data.(components{i});
    
    % Bootstrap & store the thresholds
    [lowerCutoff, upperCutoff] = u_bootstrap_corrData(currentCorr, currentNull, alphaVal);
    meanCorrData.info.cutoffs.(components{i}) = [lowerCutoff upperCutoff];
    
    progressbar(i/length(components))
end

% Save the results
saveStr = [savePathData '\meanCorrData_EEG_IC_' saveTag '_' saveID '.mat'];
save(saveStr, 'meanCorrData', '-v7.3')