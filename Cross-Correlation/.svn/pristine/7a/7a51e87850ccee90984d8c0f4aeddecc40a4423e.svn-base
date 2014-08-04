function ar_FDR_EB(fileStruct, paramStruct)

%% Initialize
% Load the data to be bootstrapped
load meanCorrData_EEG_BOLD;

% Initialize function-specific parameters
electrodes = paramStruct.xcorr.EEG_BOLD.electrodes;

%% Bootstrap the Data
for i = 1:length(electrodes)    
    % Get the electrode-specific cross-correlation data
    currentCorr = meanCorrData.data.(electrodes{i});
    
    % Bootstrap & store the thresholds
    [lowerCutoff upperCutoff] = u_CA_FDR_corrData(currentCorr, paramStruct.xcorr.EEG_BOLD.alpha);
    meanCorrData.info.cutoffs.(electrodes{i}) = [lowerCutoff upperCutoff];
    
    % Fisher's r-to-z transform
    currentCorr = atanh(currentCorr);
    meanCorrData.data.(electrodes{i}) = currentCorr;
end

% Save the results
save([fileStruct.paths.MAT_files '/xcorr/meanCorrData_EEG_BOLD_transformed.mat'], 'meanCorrData', '-v7.3');
