%% 20140414

%% 1159 - Regenerating EEG Power Spectra Plots
% Using wide-band DC EEG data originally generated on 20140205
cle
load masterStructs;
channels = {'AF7', 'FPZ', 'C3', 'PO8', 'PO10'};
specFiles = get(fileData([fileStruct.Paths.Desktop '/EEG Power Spectra']), 'Path');

% Sort the data files so they're plotted in the correct order
order = cellfun(@(x) strfind(specFiles, x), channels, 'UniformOutput', false);
currentOrder = zeros(1, length(order));
for a = 1:length(order)
    idx = cellfun(@isempty, order{a});
    idx = find(~idx);
    currentOrder(a) = idx;
end
specFiles = specFiles(currentOrder);

figHandle = windowObj('Size', 'fullscreen');
set(figHandle, 'Color', 'w');

for a = 1:length(specFiles)
    load(specFiles{a});
    axesHandle = subplot(2, 3, a);
    channel = meanSpectralData.Channels{1};
    shadePlot(...
        meanSpectralData.Data.Frequencies,...
        meanSpectralData.Data.(channel).Mean,...
        meanSpectralData.Data.(channel).SEM,...
        '-k',...
        'AxesHandle', axesHandle,...
        'LineWidth', 2);
    
    set(axesHandle,...
        'FontSize', 20,...
        'XLim', [0 0.5],...
        'XTick', 0:0.25:0.5,...
        'YLim', [0 12],...
        'YTick', 0:6:12);
    xlabel('Frequency (Hz)', 'FontSize', 25);
    ylabel('Mag^2', 'FontSize', 25);
    title(meanSpectralData.Channels{1}, 'FontSize', 25, 'FontWeight', 'bold');
end
    
saveas(figHandle.FigureHandle, [fileStruct.Paths.Desktop '/Power Spectra Montage.fig'], 'fig');
saveas(figHandle.FigureHandle, [fileStruct.Paths.Desktop '/Power Spectra Montage.png'], 'png');
saveas(figHandle.FigureHandle, [fileStruct.Paths.Desktop '/Power Spectra Montage.eps'], 'eps');
        

%% 1234 - Regenerating BOLD-EEG Partial Coherence Plots
% Using 20140121_GSControl data (where the BOLD GS is regressed from both EEG & BOLD data sets)
cle
load masterStructs;
channels = {'AF7', 'FPZ', 'C3', 'PO8', 'PO10'};
cohFiles = get(fileData([fileStruct.Paths.Desktop '/MS Coherence']), 'Path');

% Sort the data files so they're plotted in the correct order
order = cellfun(@(x) strfind(cohFiles, x), channels, 'UniformOutput', false);
currentOrder = zeros(1, length(order));
for a = 1:length(order)
    idx = cellfun(@isempty, order{a});
    idx = find(~idx);
    currentOrder(a) = idx;
end
cohFiles = cohFiles(currentOrder);

figHandle = windowObj('Size', 'fullscreen');
set(figHandle, 'Color', 'w');
% set(figHandle, 'Color', 'w', 'MenuBar', 'figure');

for a = 1:length(cohFiles)
    load(cohFiles{a});
    axesHandle = subplot(2, 3, a);
    channel = meanCohData.Parameters.Coherence.Channels{1};
    shadePlot(...
        meanCohData.Parameters.Coherence.Frequencies,...
        meanCohData.Data.(channel).Mean,...
        meanCohData.Data.(channel).SEM,...
        '-k',...
        'AxesHandle', axesHandle,...
        'LineWidth', 2,...
        'Threshold', meanCohData.Parameters.SignificanceCutoffs.(channel));
    
    set(axesHandle,...
        'FontSize', 20,...
        'XLim', [0 0.25],...
        'XTick', 0:0.125:0.25,...
        'YLim', [0 1],...
        'YTick', 0:0.5:1);
    xlabel('Frequency (Hz)', 'FontSize', 25);
    ylabel('Coherence', 'FontSize', 25);
    title(channel, 'FontSize', 25, 'FontWeight', 'bold');
end

saveas(figHandle.FigureHandle, [fileStruct.Paths.Desktop '/Coherence Montage.fig'], 'fig');
saveas(figHandle.FigureHandle, [fileStruct.Paths.Desktop '/Coherence Montage.png'], 'png');
saveas(figHandle.FigureHandle, [fileStruct.Paths.Desktop '/Coherence Montage.eps'], 'eps');
