%% 20130921

%% 1540
% Generate images of thresholded partial correlation results
pcorrPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG'];
searchStr = 'meanPartialCorrObject';
corrFiles = get(fileData(pcorrPath, 'search', searchStr), 'Path');

for a = 1:length(corrFiles)
    load(corrFiles{a})
    brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
    store(brainData, 'ext', {'png', 'fig', 'pdf'});
    close(brainData)
end


%% 1556
% Regenerate partial correlation data using CSR EEG data
ccStruct = parameters(corrObj);
ccStruct.Initialization.GSR = [false true];
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

for a = 2:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData, 'Name', ['partialCorrObject_RS_BOLD-' channels{a} '_dcCSRZ_20130921.mat'], 'varName', 'corrData');
    meanCorrData = mean(corrData);
    threshold(meanCorrData);
    store(meanCorrData, 'Name', ['meanPartialCorrObject_RS_BOLD-' channels{a} '_dcCSRZ_20130921.mat'], 'varName', 'meanCorrData');
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'fig', 'pdf'});
    close(brainData);
    brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
    clear corrData meanCorrData
end
