%% 20130920

%% 0805
% Regenerate BOLD-EEG partial correlations using EEG CSR data (in contrast to last night)
% Regenerate partial correlation results & store images
ccStruct = parameters(corrObj);
ccStruct.Initialization.GSR = [false true];
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

for a = 2:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'pdf'});
    close(brainData);
    clear corrData meanCorrData
end


%% 1528
% Order the BOLD nuisance parameter fields so that they're regressed in the correct order during
% partial correlation.
load masterStructs
searchStr = 'dcZ_20130919';
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', searchStr), 'Path');

% Finish preprocessing of raw data (correct GM & WM segment switching)
progBar = progress('Processing BOLD Data');
for a = 1:length(boldFiles)
    
    % Load the raw data
    load(boldFiles{a})
    
    for b = 1:length(boldData)
        boldData(b).Data.Nuisance = orderfields(boldData(b).Data.Nuisance, {'Motion', 'Global', 'WM', 'CSF'});
    end
    
    store(boldData);
    clear boldData
    update(progBar, a/length(boldFiles));
end
close(progBar)


%% 1556
% Regenerate partial correlation results & store images
ccStruct = parameters(corrObj);
ccStruct.Initialization.GSR = [false false];
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

for a = 1:1 %length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'pdf'});
    close(brainData);
    clear corrData meanCorrData
end


%% 1748
% Threshold partial correlations for significance
load masterStructs
pcorrPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG'];
searchStr = 'meanPartialCorrObject';
corrFiles = get(fileData(pcorrPath, 'search', searchStr), 'Path');

progBar = progress('Thresholding Correlation Maps');
for a = 2:length(corrFiles)
    load(corrFiles{a});
    threshold(meanCorrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
    update(progBar, a/length(corrFiles));
end
close(progBar)