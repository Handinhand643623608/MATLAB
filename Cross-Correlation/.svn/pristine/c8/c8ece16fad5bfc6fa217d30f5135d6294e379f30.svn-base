function ar_FDR_EI(fileStruct, paramStruct)

%% Initialize
% Load the data
load meanCorrData_EEG_IC

% Initialize function-specific parameters
if isempty(paramStruct.xcorr.EEG_IC.subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.xcorr.EEG_BOLD.subjects;
    scans = paramStruct.xcorr.EEG_BOLD.scans;
end
components = meanCorrData.info.componentIdents;

%% Bootstrap the Data
for i = 1:length(components)
    % Get the network-specific cross-correlation data
    currentCorr = meanCorrData.data.(components{i});
        
    % Bootstrap & store the thresholds
    [lowerCutoff upperCutoff] = u_CA_FDR_corrData(currentCorr);
    meanCorrData.info.cutoffs.(components{i}) = [lowerCutoff upperCutoff];
    
    % Fisher's r-to-z transform
    currentCorr = atanh(currentCorr);
    meanCorrData.data.(components{i}) = currentCorr;    
end

% Save the results
save([fileStruct.paths.MAT_files '\xcorr\meanCorrData_EEG_IC.mat'], 'meanCorrData', '-v7.3')
    