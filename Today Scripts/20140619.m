%% 20140619 


%% 1256 - Investigating PCA for Identification of Global Signals

% Load & condition BOLD data
load boldObject-1_RS_dcZ_20131030;
funData = ToMatrix(boldData(1));
idsNaN = isnan(funData(:, 1));
funData(idsNaN, :) = [];

% Run PCA to identify spatial components explaining maximal variance
funData = funData';
[pcaCoeff, pcaScore] = pca(funData);

% Extract & reshape the first spatial principal component
comp1 = nan(length(idsNaN));
comp1(~idsNan) = pcaCoeff(:, 1);
comp1 = reshape(comp1, [91 109 91]);

% Plot the first principal component
figure;
imagesc(comp1(:, :, 50));

% Run PCA to identify temporal components explaining maximal variance
funData = funData';
[pcaCoeff, pcaScore] = pca(funData);

% Extract & plot the first temporal principal component
comp1 = pcaCoeff(:, 1);
figure;
plot((1:218)*2, comp1, 'LineWidth', 2);
xlabel('Time (s)');
title('First Temporal Principal Component');

% Results: Not clear how the spatial component could be used as a surrogate for global data. And the temporal component
% doesn't look anything like the global signal obtained through averaging all voxel time series. This looks like a dead
% end for now.
%
% It's entirely possible that I'm misunderstanding how PCA is working in MATLAB. The documentation is a little vague,
% especially on the meanings behind the outputted coefficients and scores. Might have to revisit this topic later.



%% 1418 - Investigating tICA of EEG Signals

% 
numIC = 30;

load eegObject-1_RS_dcZ_20130906;
ephysData = eegData(1).Data.EEG;
idsNaN = isnan(ephysData(:, 1));
ephysData(idsNaN, :) = [];


eegIC = fastica(ephysData,...
    'Approach', 'defl',...
    'numOfIC', numIC);

corrData = nan(length(idsNaN), numIC);
for a = 1:numIC;
    corrData(~idsNaN, a) = xcorrArr(eegIC(a, :), ephysData, 'MaxLag', 0);
end

window = brainPlot('eeg', corrData,...
    'CLim', [-0.25 0.25],...
    'Title', 'IC-EEG Correlation',...
    'XLabel', 'IC Number',...
    'XTickLabel', 1:numIC);



%% 1503 - Running BOLD GS - EEG GS Cross Correlation

timeStamp = '201406191503';
analysisStr = 'BOLD Global - EEG Correlation';
shiftsToPlot = -20:2:20;
saveStr = '%s/%s - %s';

corrStruct(8, 2) = struct(...
    'Data', [],...
    'SampleShifts', [],...
    'TimeShifts', []);



load masterStructs
saveStr = sprintf(saveStr, fileStruct.Paths.TodayData, timeStamp, analysisStr);

boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', '_dcZ'), 'Path');
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', '_dcZ'), 'Path');

pbar = progress(analysisStr);
for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    load(eegFiles{a});
    
    for b = 1:2
        
        boldGS = boldData(b).Data.Nuisance.Global;
        ephysData = eegData(b).Data.EEG;
        
        [cxy, lags] = xcorrArr(boldGS, ephysData);
        
        corrStruct(a, b).Data = cxy;
        corrStruct(a, b).SampleShifts = lags;
        corrStruct(a, b).TimeShifts = lags*2;
    end
    update(pbar, a/length(boldFiles));
end
close(pbar);

save([saveStr '.mat'], 'corrStruct', '-v7.3');

meanCorrStruct = corrStruct(1, 1);
catData = [];
for a = 1:numel(corrStruct)
    catData = cat(3, catData, corrStruct(a).Data);
end
meanCorrStruct.Data = nanmean(catData, 3);

idsShifts = ismember(meanCorrStruct.TimeShifts, shiftsToPlot);
corrPlot = brainPlot('eeg', meanCorrStruct.Data(:, idsShifts),...
    'Title', ['Average ' analysisStr],...
    'XTickLabel', shiftsToPlot);

saveas(corrPlot.FigureHandle, [saveStr '.png'], 'png');