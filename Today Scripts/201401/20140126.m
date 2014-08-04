%% 20140126


%% 1055 - BOLD-EEG Partial Correlation Significance Thresholding (BOLD GSR Control, No EEG CSR)
% Need to regenerate thresholded partial correlation data for use in the publication
load masterStructs
searchStr = 'mean.*dcZ_20131126';
corrFiles = get(fileData([fileStruct.Paths.DataObjects '\Partial Correlation\BOLD-EEG'], 'Search', searchStr), 'Path');

% Test out the first correlation thresholding
load(corrFiles{1});
threshold(meanCorrData);

% Plot the thresholded data
brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
store(brainData, 'ext', {'png', 'fig'});
    

%% 0156 - Threshold the Rest of the Correlation Data Above
load masterStructs
searchStr = 'mean.*dcZ_20131126';
corrFiles = get(fileData([fileStruct.Paths.DataObjects '\Partial Correlation\BOLD-EEG'], 'Search', searchStr), 'Path');

progBar = progress('Correlation Data Thresholded');
for a = 2:length(corrFiles)
    load(corrFiles{a});
    threshold(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
    store(brainData, 'ext', {'png', 'fig'});
    clear meanCorrData
    update(progBar, a/length(corrFiles));
end
close(progBar);

% Finished @ 1301 on 20140127. Threshold values stored under original correlation data objects:
%   meanPartialCorrObject_RS_BOLD-[Channel]_dcZ_20131126
