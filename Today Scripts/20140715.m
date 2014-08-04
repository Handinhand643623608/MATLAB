%% 20140715 


%% 0019 - Sub-Alpha EEG Interelectrode Correlations
% Today's parameters
timeStamp = '201407150019';
analysisStamp = 'Sub-Alpha EEG Interelectrode Correlations';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140715/201407150019 - %s%s';
imSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140715/201407150019-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject', 'Ext', '.mat');

corrData = nan(68, 68, 17);

% Create & image correlations by scan
pbar = progress('Sub-Alpha EEG Interelectrode Correlations');
for a = 1:length(eegFiles)
    load(eegFiles{a})
    Filter(eegData, 'Passband', [0.01, 8]);
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

% Results: All strongly and positively correlated again.
%
% Might need to look at interelectrode correlations on an individual frequency band basis instead of including
% everything up to a point. If synchrony between signals occurs at different times (as a function of frequency band),
% then using such wide-band data may result in the universal strong correlations being seen so far. Will have to try
% this later.



%% 1200 - Infraslow EEG Phase Mapping
% During our meeting last week, Shella and Chip suggested a possible new way of choosing electrodes to compare with BOLD
% data. This was a consistent gripe among the reviewers of the BOLD-EEG manuscript; neither of them liked the way have
% been doing it (i.e. anticorrelated channel pairings). They suggested that we might be able to produce groupings of
% electrode based on signal phase.
%
% One of the suggestions involved comparing electrode phases with a chosen reference signal (e.g. FPz, or something).
% I suggested that we might be able to use instantaneous signal phase through the Hilbert transform. If electrodes can
% be consistently grouped together across scans by signal phase alone, then we might be able to leverage this approach
% to choose substantially different infraslow signals for comparisons with BOLD.
%
% The following analysis uses the Hilbert transform to produce the analytic forms of EEG electrode time series. The
% analytic signals are complex valued, with a real part that is identical to the original signal and an imaginary part
% that is a version of the real part with a 90 degree phase shift. The instantaneous phase is calculated as the
% arctangent of the imaginary and real parts. Consideration is given to the Euclidean graph quadrant of the complex
% vectors that make up a given time series. Thus, for any electrode time series with analytic form x(t):
%
%   phase(t) = atan2(imag(x(t)), real(x(t))

% Today's parameters
timeStamp = '201407151200';
analysisStamp = 'EEG Phase Mapping';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140715/201407151200 - %s%s';

% Plot parameters
timesToPlot = round(linspace(1, 218, 20));

eegFiles = GetEEG(Paths);

hilbertData = nan(68, 218, 17);
phaseData = nan(68, 218, 17);

for a = 1:length(eegFiles)
    load(eegFiles{a});
    
    ephysData = ToArray(eegData);
    ephysData = ephysData';
    
    hilbertData(:, :, a) = hilbert(ephysData)'; 
    phaseData(:, :, a) = atan2(imag(hilbertData(:, :, a)), real(hilbertData(:, :, a)));
end

brainData = brainPlot('eeg', phaseData(:, timesToPlot, :),...
    'CLim', [-pi pi],...
    'ColorbarLabel', 'Phase Angle (rad)',...
    'Title', 'EEG Instantaneous Phase Mappings',...
    'XLabel', 'Time (s)',...
    'XTickLabel', timesToPlot./eegData.Fs,...
    'YLabel', 'Scan Number',...
    'YTickLabel', 1:17);

set(brainData.Colorbar, 'FontSize', 15, 'YTick', [-pi:pi/2:pi]);

dataSaveStr = sprintf(dataSaveName, analysisStamp, '.mat');
save(dataSaveStr, 'hilbertData', 'phaseData', '-v7.3');
Store(brainData,...
    'Name', [timeStamp ' - ' analysisStamp],...
    'Path', get(Paths, 'TodayData'),...
    'Ext', {'png', 'fig'});





%% 1342 - 
% Today's parameters
timeStamp = '201407151342';

%
scans = {[1 2], [1 2], [1 2], [1 2], [1 2], [1 2 3], [1 2], [1 2]};
rawFolders = Contents(Paths, 'Raw');

for a = 1:length(rawFolders)
    cntFiles = search([rawFolders{a} '/EEG'], [], 'Ext', '.cnt');
    
    for b = scans{a}
        
        
    end
end