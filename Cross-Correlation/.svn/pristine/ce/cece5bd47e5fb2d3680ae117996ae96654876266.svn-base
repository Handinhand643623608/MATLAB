function f_CA_run_bootstrap_BI(fileStruct, paramStruct)

%% Initialize
% Load the data
load meanCorrData_BLP_IC_alpha
load meanNullData_BLP_IC_alpha

% Initialize function-specific parameters
if isempty(paramStruct.xcorr.BLP_IC.alpha.subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.xcorr.BLP_IC.alpha.subjects;
    scans = paramStruct.xcorr.BLP_IC.alpha.scans;
end
components = meanCorrData.info.componentIdents;

%% Bootstrap the Data
progressStr = ['Alpha BLP-IC Bootstrapping'];
progressbar(progressStr)
for i = 1:length(components)
    % Get the network-specific cross-correlation data
    currentCorr = meanCorrData.data.(components{i});
    currentNull = meanNullData.data.(components{i});
        
    % Bootstrap & store the thresholds
    [lowerCutoff upperCutoff] = u_CA_bootstrap_corrData(currentCorr, currentNull, paramStruct.xcorr.BLP_IC.alpha.alpha);
    meanCorrData.info.cutoffs.(components{i}) = [lowerCutoff upperCutoff];
    
    progressbar(i/length(components))
end

% Save the results
saveStr = [fileStruct.paths.MAT_files '\xcorr\meanCorrData_BLP_IC_alpha.mat'];
save(saveStr, 'meanCorrData', '-v7.3')
    