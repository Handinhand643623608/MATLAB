%% 20130923

%% 1640
% EEG inter-electrode correlation maps (pre-CSR)
load masterStructs
searchStr = 'dcZ';
searchPath = [fileStruct.Paths.DataObjects '/EEG'];
eegFiles = get(fileData(searchPath, 'search', searchStr), 'Path');

% Concatenate inter-electrode correlations
currentCorr = [];
for a = 1:length(eegFiles);
    load(eegFiles{a});
    
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            currentCorr = cat(3, currentCorr, corrcoef(eegData(b).Data.EEG'));
        end
    end
end

% Convert to normalized Z-scores & average correlation values
% currentCorr = atanh(currentCorr).*sqrt(size(eegData(1).Data.EEG, 2) - 3);
meanCorr = nanmean(currentCorr, 3);
channels = eegData(1).Channels;

% Sort correlation values
[~, idsSorted] = sort(meanCorr);
ascendCount = zeros(1, size(meanCorr, 1));
for a = 1:size(idsSorted, 2)
    sortedCorr = meanCorr(idsSorted(:, a), idsSorted(:, a));
    checkAscending = sortedCorr(2:end, 2:end) > sortedCorr(1:end-1, 1:end-1);
    ascendCount(a) = sum(checkAscending(:));
end
idsSorted = idsSorted(:, ascendCount == max(ascendCount));
meanCorr = meanCorr(idsSorted, idsSorted);
channels = channels(idsSorted);

% Generate an image of the correlation data (pre-CSR)
figHandle = windowObj('size', 'fullscreen');
imagesc(meanCorr, [-1 1]);
axis square; colorbar
title('Average Inter-Electrode Correlations Before CSR', 'FontSize', 16)
labelFigure('xLabels', channels', 'xRotation', 90, 'yLabels', channels);
saveas(gcf, [fileStruct.Paths.Desktop '/No CSR.png'], 'png');
saveas(gcf, [fileStruct.Paths.Desktop '/No CSR.fig'], 'fig');


%% 1655
% EEG inter-electrode correlation maps (post-CSR)
load masterStructs
searchStr = 'dcGRZ';
searchPath = [fileStruct.Paths.DataObjects '/EEG'];
eegFiles = get(fileData(searchPath, 'search', searchStr), 'Path');

% Concatenate inter-electrode correlations
currentCorr = [];
for a = 1:length(eegFiles);
    load(eegFiles{a});
    
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            currentCorr = cat(3, currentCorr, corrcoef(eegData(b).Data.EEG'));
        end
    end
end

% Convert to normalized Z-scores & average correlation values
% currentCorr = atanh(currentCorr).*sqrt(size(eegData(1).Data.EEG, 2) - 3);
meanCorr = nanmean(currentCorr, 3);
channels = eegData(1).Channels;

% Sort correlation values
[~, idsSorted] = sort(meanCorr);
ascendCount = zeros(1, size(meanCorr, 1));
for a = 1:size(idsSorted, 2)
    sortedCorr = meanCorr(idsSorted(:, a), idsSorted(:, a));
    checkAscending = sortedCorr(2:end, 2:end) > sortedCorr(1:end-1, 1:end-1);
    ascendCount(a) = sum(checkAscending(:));
end
idsSorted = idsSorted(:, ascendCount == max(ascendCount));
meanCorr = meanCorr(idsSorted, idsSorted);
channels = channels(idsSorted);

% Generate an image of the correlation data (post-CSR)
figHandle = windowObj('size', 'fullscreen');
imagesc(meanCorr, [-1 1]);
axis square; colorbar
title('Average Inter-Electrode Correlations Before CSR', 'FontSize', 16)
labelFigure('xLabels', channels', 'xRotation', 90, 'yLabels', channels);
saveas(gcf, [fileStruct.Paths.Desktop '/CSR.png'], 'png');
saveas(gcf, [fileStruct.Paths.Desktop '/CSR.fig'], 'fig');


%% 1823
% Determined that there's a problem with partial correlations as I've been running them. Signal regressions (nuisance
% signals) are not being performed properly. Need to re-do correlations
ccStruct = parameters(corrObj);
ccStruct.Initialization.GSR = [false true];
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

progBar = progress('Running Partial Correlations');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData, 'Name', ['partialCorrObject_RS_BOLD-' channels{a} '_dcCSRZ_20130921.mat'], 'varName', 'corrData');
    meanCorrData = mean(corrData);
    store(meanCorrData, 'Name', ['meanPartialCorrObject_RS_BOLD-' channels{a} '_dcCSRZ_20130921.mat'], 'varName', 'meanCorrData');
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'fig', 'pdf'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);


%% 1945
% Run cross correlation without any nuisance signal regressions (but still with EEG CSR)
ccStruct = parameters(corrObj);
ccStruct.Initialization.Relation = 'Partial Correlation';
ccStruct.Initialization.GSR = [false true];
ccStruct.Correlation.Control = 'BOLD Global';
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

progBar = progress('Running Partial Correlations');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'fig'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);

% 2139 - Abandoned this approach because images basically replicate past results (with strong
% ventricular correlations)


%% 2139
% Run cross correlation without EEG CSR
ccStruct = parameters(corrObj);
ccStruct.Initialization.Relation = 'Partial Correlation';
ccStruct.Initialization.GSR = [false false];
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

progBar = progress('Running Partial Correlations');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'fig'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);


%% 2057
% Threshold & plot correlations run @ 1823 today
load masterStructs
searchPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG'];
searchStr = 'meanPartialCorrObject_RS_BOLD-.*_dcCSR';
ccFiles = get(fileData(searchPath, 'search', searchStr), 'Path');

progbar = progress('Thresholding Mean Partial Correlation Data');
for a = 1:length(ccFiles)
    load(ccFiles{a})
    threshold(meanCorrData)
    [~, fileName, ~] = fileparts(ccFiles{a});
    store(meanCorrData, 'Name', [fileName '.mat'], 'varName', 'meanCorrData');
    brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
    store(brainData, 'ext', {'png', 'fig'});
    update(progbar, a/length(ccFiles));
end


threshold(meanCorrData, meanNullData);
[~, fileName, ~] = fileparts(ccFiles{a});
store(meanCorrData, 'Name', [fileName '.mat'], 'varName', 'meanCorrData');
brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
store(brainData, 'ext', {'png', 'fig'});