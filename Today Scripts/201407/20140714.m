%% 20140714 



%% 1612 - Separating Full-Band EEG Data by Scans
% Today's parameters
timeStamp = '201407141612';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject', 'Ext', '.mat');

pbar = progress('Splitting Full-Band EEG Data Objects');
for a = 1:length(eegFiles)
    load(eegFiles{a}) 
    for b = 1:length(eegData)
        savePath = [get(Paths, 'EEG') '/Unfiltered'];
        if ~isempty(eegData(b).Data)
            Standardize(eegData(b));
            Store(eegData(b), 'Path', savePath, 'Overwrite', true);
        end
    end
    update(pbar, a/length(eegFiles));
end
close(pbar);



%% 1617 - Full-Band EEG Interelectrode Correlations
% During a meeting with Chip last Wednesday (20140709), it was suggested that the reason we might be seeing such strong
% positive correlations between infraslow signals is that anticorrelations reside in other frequency bands. One of the
% BOLD-EEG manuscript reviewers said that anticorrelations between electrodes should always exist because currents don't
% leave the head. Thus, this analysis is being done to investigate if any consistent anticorrelations exist between
% electrodes using full-bandwidth (0-100 Hz) EEG data. 

% Today's parameters
timeStamp = '201407141617';
analysisStamp = 'Full-Band EEG Interelectrode Correlations';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141617 - %s%s';
imSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141617-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject', 'Ext', '.mat');

corrData = nan(68, 68, 17);

% Create & image correlations by scan
pbar = progress('Full-Band EEG Interelectrode Correlations');
for a = 1:length(eegFiles)
    load(eegFiles{a})
    ephysData = ToArray(eegData);
    corrData(:, :, a) = corrcoef(ephysData');
    
    figure;
    imagesc(corrData(:, :, a), [-1 1]);
    cbar = colorbar;
    set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
    set(cbar, 'YTick', -1:0.5:1);
    set(gca, 'FontSize', 20);
    set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
    xlabel('Electrode Index', 'FontSize', 25);
    ylabel('Electrode Index', 'FontSize', 25);
    imSaveStrPNG = sprintf(imSaveName, a, analysisStamp, '.png');
    imSaveStrFIG = sprintf(imSaveName, a, analysisStamp, '.fig');
    saveas(gcf, imSaveStrPNG, 'png');
    saveas(gcf, imSaveStrFIG, 'fig');
    close;
    
    update(pbar, a/length(eegFiles));
end
close(pbar);

% Average data together & save everything
meanCorrData = nanmean(corrData, 3);
dataSaveStr = sprintf(dataSaveName, analysisStamp, '.mat');
save(dataSaveStr, 'corrData', 'corrData', 'meanCorrData', '-v7.3');

% Image the average interelectrode correlations
figure;
imagesc(meanCorrData, [-1 1]);
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', -1:0.5:1);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
imSaveStrPNG = sprintf(dataSaveName, analysisStamp, '.png');
imSaveStrFIG = sprintf(dataSaveName, analysisStamp, '.fig');
saveas(gcf, imSaveStrPNG, 'png');
saveas(gcf, imSaveStrFIG, 'fig');
close all

% Results: These too appear very strongly and universally correlated. Average interelectrode correlations hover near 1,
% and single-scan images aren't really any better. 
%
% This is bad news I think. The fact that everything correlates to one another corroborates the reviewer's suggestion
% that we have collected meaningless data. 
%
% However, it could be that the current passband is too wide for our applications. The debate continues on how high real
% neuronal oscillation frequencies can climb, but it's almost certain that our recording equipment isn't capturing
% high-fidelity signals as high as 100 Hz. There's probably a lot of noise at such high frequencies, and the referential
% system that is EEG means that this can introduce correlations if the amplifier isn't able to get rid of it all.



%% 1709 - Infraslow EEG Interelectrode Correlations
% Before I start narrowing the passband on the non-infraslow EEG data, I just realized that I don't have good images of
% correlations between infraslow EEG signals. I have the average signals, but I don't have any recent images on a
% per-scan basis. This will fill that gap.

% Today's parameters
timeStamp = '201407141709';
analysisStamp = 'Infraslow EEG Interelectrode Correlations';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141709 - %s%s';
imSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141709-%d - %s%s';

eegFiles = GetEEG(Paths);

corrData = nan(68, 68, 17);

% Create & image correlations by scan
pbar = progress('Full-Band EEG Interelectrode Correlations');
for a = 1:length(eegFiles)
    load(eegFiles{a})
    ephysData = ToArray(eegData);
    corrData(:, :, a) = corrcoef(ephysData');
    
    figure;
    imagesc(corrData(:, :, a), [-1 1]);
    cbar = colorbar;
    set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
    set(cbar, 'YTick', -1:0.5:1);
    set(gca, 'FontSize', 20);
    set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
    xlabel('Electrode Index', 'FontSize', 25);
    ylabel('Electrode Index', 'FontSize', 25);
    imSaveStrPNG = sprintf(imSaveName, a, analysisStamp, '.png');
    imSaveStrFIG = sprintf(imSaveName, a, analysisStamp, '.fig');
    saveas(gcf, imSaveStrPNG, 'png');
    saveas(gcf, imSaveStrFIG, 'fig');
    close;
    
    update(pbar, a/length(eegFiles));
end
close(pbar);

% Average data together & save everything
meanCorrData = nanmean(corrData, 3);
dataSaveStr = sprintf(dataSaveName, analysisStamp, '.mat');
save(dataSaveStr, 'corrData', 'corrData', 'meanCorrData', '-v7.3');

% Image the average interelectrode correlations
figure;
imagesc(meanCorrData, [-1 1]);
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', -1:0.5:1);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
imSaveStrPNG = sprintf(dataSaveName, analysisStamp, '.png');
imSaveStrFIG = sprintf(dataSaveName, analysisStamp, '.fig');
saveas(gcf, imSaveStrPNG, 'png');
saveas(gcf, imSaveStrFIG, 'fig');
close all

% Results: These appear similar enough to some single-scan images of this I had generated a long time ago (20120813, by
% the looks of it). Those correlations were sorted, so it's impossible to say that they're exactly equivalent by visual
% inspection alone, but they're close enough to satisfy my curiosity. 
%
% About half of the images exhibit strongly positive and nearly univeral correlations between signals. The other half
% are more variable, and anticorrelations are indeed observed. Bad channels are clearly evident for many subjects as
% well, I think. 
%
% Going to try narrowing the bandwidth of the EEG signals from above for this analysis.



%% 1732 - Sub-Gamma EEG Interelectrode Correlations
% Let's cut out the gamma band first, because I've read that acquiring data from those frequencies often requires
% special preparations and oscillations of such high frequencies may not even pass through the skull at all. Gamme band
% ranges between 30-100 Hz.


% Today's parameters
timeStamp = '201407141732';
analysisStamp = 'Sub-Gamma EEG Interelectrode Correlations';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141732 - %s%s';
imSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141732-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject', 'Ext', '.mat');

corrData = nan(68, 68, 17);

% Create & image correlations by scan
pbar = progress('Sub-Gamma EEG Interelectrode Correlations');
for a = 1:length(eegFiles)
    load(eegFiles{a})
    Filter(eegData, 'Passband', [0.01, 30]);
    ephysData = ToArray(eegData);
    corrData(:, :, a) = corrcoef(ephysData');
    
    figure;
    imagesc(corrData(:, :, a), [-1 1]);
    cbar = colorbar;
    set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
    set(cbar, 'YTick', -1:0.5:1);
    set(gca, 'FontSize', 20);
    set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
    xlabel('Electrode Index', 'FontSize', 25);
    ylabel('Electrode Index', 'FontSize', 25);
    imSaveStrPNG = sprintf(imSaveName, a, analysisStamp, '.png');
    imSaveStrFIG = sprintf(imSaveName, a, analysisStamp, '.fig');
    saveas(gcf, imSaveStrPNG, 'png');
    saveas(gcf, imSaveStrFIG, 'fig');
    close;
    
    update(pbar, a/length(eegFiles));
end
close(pbar);

% Average data together & save everything
meanCorrData = nanmean(corrData, 3);
dataSaveStr = sprintf(dataSaveName, analysisStamp, '.mat');
save(dataSaveStr, 'corrData', 'corrData', 'meanCorrData', '-v7.3');

% Image the average interelectrode correlations
figure;
imagesc(meanCorrData, [-1 1]);
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', -1:0.5:1);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
imSaveStrPNG = sprintf(dataSaveName, analysisStamp, '.png');
imSaveStrFIG = sprintf(dataSaveName, analysisStamp, '.fig');
saveas(gcf, imSaveStrPNG, 'png');
saveas(gcf, imSaveStrFIG, 'fig');
close all

% Results: These are all really strongly correlated again. This isn't a good sign; 30 Hz isn't that high for brain
% activity. Going to try filtering down the signals some more.



%% 1913 - Sub-Beta EEG Interelectrode Correlations
% Today's parameters
timeStamp = '201407141913';
analysisStamp = 'Sub-Beta EEG Interelectrode Correlations';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141913 - %s%s';
imSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140714/201407141913-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject', 'Ext', '.mat');

corrData = nan(68, 68, 17);

% Create & image correlations by scan
pbar = progress('Sub-Beta EEG Interelectrode Correlations');
for a = 1:length(eegFiles)
    load(eegFiles{a})
    Filter(eegData, 'Passband', [0.01, 13]);
    ephysData = ToArray(eegData);
    corrData(:, :, a) = corrcoef(ephysData');
    
    figure;
    imagesc(corrData(:, :, a), [-1 1]);
    cbar = colorbar;
    set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
    set(cbar, 'YTick', -1:0.5:1);
    set(gca, 'FontSize', 20);
    set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
    xlabel('Electrode Index', 'FontSize', 25);
    ylabel('Electrode Index', 'FontSize', 25);
    imSaveStrPNG = sprintf(imSaveName, a, analysisStamp, '.png');
    imSaveStrFIG = sprintf(imSaveName, a, analysisStamp, '.fig');
    saveas(gcf, imSaveStrPNG, 'png');
    saveas(gcf, imSaveStrFIG, 'fig');
    close;
    
    update(pbar, a/length(eegFiles));
end
close(pbar);

% Average data together & save everything
meanCorrData = nanmean(corrData, 3);
dataSaveStr = sprintf(dataSaveName, analysisStamp, '.mat');
save(dataSaveStr, 'corrData', 'corrData', 'meanCorrData', '-v7.3');

% Image the average interelectrode correlations
figure;
imagesc(meanCorrData, [-1 1]);
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', -1:0.5:1);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
imSaveStrPNG = sprintf(dataSaveName, analysisStamp, '.png');
imSaveStrFIG = sprintf(dataSaveName, analysisStamp, '.fig');
saveas(gcf, imSaveStrPNG, 'png');
saveas(gcf, imSaveStrFIG, 'fig');
close all;

% Results: All strongly correlated.