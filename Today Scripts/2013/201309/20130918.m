%% 20130918 - Today Script

%% 1704
% Plotting & saving new BOLD-EEG MS coherence images
load masterStructs
cohFiles = get(fileData([fileStruct.Paths.DataObjects '/MS Coherence'], 'Search', 'meanCohObject_*.*_20130917'), 'Path');

for a = 1:length(cohFiles)
    load(cohFiles{a})
    channel = fieldnames(meanCohData.Data);
    
    shadePlot(...
        meanCohData.Parameters.Coherence.Frequencies,...
        meanCohData.Data.(channel{1}).Mean,...
        meanCohData.Data.(channel{1}).SEM,...
        '-k',...
        'Color', 'w');
    
    xlabel('Frequency (Hz)', 'FontSize', 14);
    ylabel('Magnitude Squared Coherence', 'FontSize', 14);
    title(['BOLD-' channel{1} ' Coherence'], 'FontSize', 16);
    
    saveas(gcf, [channel{1} '.png'], 'png');
    close
end
    