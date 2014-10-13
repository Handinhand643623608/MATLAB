%% 20140618 


%% 1706 - Examining Average BOLD GS-RSN Cross-Correlations

% Parameters
timeStamp = '201406181706';
shiftsToPlot = -20:2:20;

% Get BOLD data files
load masterStructs;
saveName = [fileStruct.Paths.Desktop '/' timeStamp ' - BOLD GS-RSN Correlations'];
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');

% Initialize a correlation data storage structure
corrStruct(8, 2) = struct(...
    'Data', [],...
    'RSNNames', [],...
    'SampleLags', [],...
    'TimeLags', []);

% Cross correlate
pbar = progress('BOLD GS-RSN Cross Correlation');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    for b = 1:2         % <--- No ICA data for subject 6 scan 3
        currentGS = boldData(b).Data.Nuisance.Global;
        [currentIC, rsnNames] = ToArray(boldData(b), 'ICs');
        
        [cxy, lags] = xcorrArr(currentGS, currentIC);
        
        corrStruct(a, b).Data = cxy;
        corrStruct(a, b).RSNNames = rsnNames;
        corrStruct(a, b).SampleLags = lags;
        corrStruct(a, b).TimeLags = 2*lags;
    end
    update(pbar, a/length(boldFiles));
end
close(pbar);

% Save the correlation data
save([saveName '.mat'], 'corrStruct', '-v7.3');

% Initialize average data storage, concatenate the data, & store
meanCorrStruct = corrStruct(1, 1);
catData = [];
for a = 1:numel(corrStruct)
    catData = cat(3, catData, corrStruct(a).Data);
end
meanCorrStruct.Data = nanmean(catData, 3);

% Plot the data
corrPlot = windowObj('Size', 'fullscreen');
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
for a = 1:length(meanCorrStruct.RSNNames)
    subplot(length(meanCorrStruct.RSNNames), 1, a);
    plot(shiftsToPlot, meanCorrStruct.Data(a, idsTimeShifts), 'LineWidth', 3);
    title(meanCorrStruct.RSNNames{a});
end

% Save the image
saveas(corrPlot.FigureHandle, [saveName '.png'], 'png');



%% 1734 - Cross-Correlating BOLD & EEG Global Signals

% Parameters
timeStamp = '201406181734';
shiftsToPlot = -20:2:20;

% Get BOLD & EEG data files
load masterStructs;
saveName = [fileStruct.Paths.Desktop '/' timeStamp ' - BOLD GS-EEG GS Correlations'];
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ'), 'Path');

% Initialize a correlation data storage structure
corrStruct(8, 2) = struct(...
    'Data', [],...
    'SampleLags', [],...
    'TimeLags', []);

% Cross correlate
pbar = progress('BOLD GS-EEG GS Cross Correlation')
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    for b = 1:2
        boldGS = boldData(b).Data.Nuisance.Global;
        eegGS = nanmean(eegData(b).Data.EEG, 1);
        
        eegGS = zscore(eegGS);
        
        [cxy, lags] = xcorrArr(boldGS, eegGS);
        
        corrStruct(a, b).Data = cxy;
        corrStruct(a, b).SampleLags = lags;
        corrStruct(a, b).TimeLags = 2*lags;
    end
    update(pbar, a/length(boldFiles));
end
close(pbar);

% Save the correlation data
save([saveName '.mat'], 'corrStruct', '-v7.3');

% Initialize average data storage, concatenate the data, & store
meanCorrStruct = corrStruct(1, 1);
catData = [];
for a = 1:numel(corrStruct)
    catData = cat(1, catData, corrStruct(a).Data);
end
meanCorrStruct.Data = nanmean(catData, 3);

% Plot the data
corrPlot = windowObj('Size', 'fullscreen');
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
plot(shiftsToPlot, meanCorrStruct.Data(idsTimeShifts), 'LineWidth', 3);
title('BOLD Global - EEG Global Cross Correlation', 'FontSize', 25);
xlabel('Time Shift (s)', 'FontSize', 20);
ylabel('Pearson r', 'FontSize', 20);

% Save the image
saveas(corrPlot.FigureHandle, [saveName '.png'], 'png');



%% 2104 - 

% Parameters
timeStamp = '201406182104';
shiftsToPlot = -20:2:20;

% Get BOLD & EEG data files
load masterStructs;
saveName = [fileStruct.Paths.Desktop '/' timeStamp ' - RSN-EEG GS Correlations'];
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ'), 'Path');

% Initialize a correlation data storage structure
corrStruct(8, 2) = struct(...
    'Data', [],...
    'RSNNames', [],...
    'SampleLags', [],...
    'TimeLags', []);

% Cross correlate
pbar = progress('BOLD GS-EEG GS Cross Correlation')
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    for b = 1:2
        [rsnData, rsnNames] = ToArray(boldData(b), 'ICs');
        eegGS = nanmean(eegData(b).Data.EEG, 1);
        
        eegGS = zscore(eegGS);
        
        [cxy, lags] = xcorrArr(rsnData, eegGS);
        
        corrStruct(a, b).Data = cxy;
        corrStruct(a, b).RSNNames = rsnNames;
        corrStruct(a, b).SampleLags = lags;
        corrStruct(a, b).TimeLags = 2*lags;
    end
    update(pbar, a/length(boldFiles));
end
close(pbar);

% Save the correlation data
save([saveName '.mat'], 'corrStruct', '-v7.3');

% Initialize average data storage, concatenate the data, & store
meanCorrStruct = corrStruct(1, 1);
catData = [];
for a = 1:numel(corrStruct)
    catData = cat(1, catData, corrStruct(a).Data);
end
meanCorrStruct.Data = nanmean(catData, 3);

% Plot the data
corrPlot = windowObj('Size', 'fullscreen');
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
for a = 1:length(meanCorrStruct.RSNNames)
    subplot(length(meanCorrStruct.RSNNames), 1, a);
    plot(shiftsToPlot, meanCorrStruct.Data(a, idsTimeShifts), 'LineWidth', 3);
    title(meanCorrStruct.RSNNames{a});
end

% Save the image
saveas(corrPlot.FigureHandle, [saveName '.png'], 'png');
