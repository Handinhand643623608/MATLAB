%% 20140826 


%% 0958 - Imaging Average BOLD-EEG Partial Correlations (Excluding Subjects 5 & 6)
% Today's parameters
timeStamp = '201408260958';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140826/201408260958 - ';

ssAnalysisStamp = '%d-%d BOLD-%s Partial Correlation';
avgAnalysisStamp = 'BOLD-%s Average Partial Correlation';

slicesToPlot = 48:4:64;
shiftsToPlot = -20:2:20;
pixelCrop = 7;

% Load the Colin brain in order to use its brain mask (removes a lot of edge-of-brain junk)
load('Special Functions/@brainViewer/colinBrain.mat');
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

corrPath = [get(Paths, 'Desktop') '/Data Sets/Data Objects/Partial Correlation/BOLD-EEG'];
corrFiles = search(corrPath, '^partialCorrObject.*20140416');

for a = 1:length(corrFiles)
    
    load(corrFiles{a});
    
    corrData(1).Parameters.Correlation.Subjects(5:6) = [];
    meanCorrData = mean(corrData);
    channel = meanCorrData.Parameters.Correlation.Channels{1};
    idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
    
    for b = 1:size(corrData, 1)
        for c = 1:size(corrData, 2)
            if ~isempty(corrData(b, c).Data)
                currentData = corrData(b, c).Data.(channel);

                for d = 1:size(currentData, 4)
                    temp = currentData(:, :, :, b);
                    temp(colinMask == 0) = NaN;
                    currentData(:, :, :, b) = temp;
                end

                % Create the montage
                brainData(b, c) = brainPlot(...
                    'mri',...
                    currentData(:, :, slicesToPlot, idsShifts),...
                    'AxesColor', 'k',...
                    'CLim', [-3 3],...
                    'Color', 'w',...
                    'ColorbarLabel', 'Z-Scores',...
                    'Title', ['BOLD-' channel],...
                    'XLabel', 'Time Shift (s)',...
                    'XTickLabel', shiftsToPlot,...
                    'YLabel', 'Slice Number',...
                    'YTickLabel', slicesToPlot);

                % Adjust some properties
                set(brainData(b, c).Axes.Primary, 'Color', 'k');
                set(brainData(b, c).Axes.Primary, 'FontSize', 20);
                set(get(brainData(b, c).Colorbar, 'YLabel'), 'FontSize', 25);

                imSaveName = [dataSaveName sprintf(ssAnalysisStamp, b, c, channel)];

                saveas(brainData(b, c).FigureHandle, [imSaveName '.png'], 'png');
                saveas(brainData(b, c).FigureHandle, [imSaveName '.fig'], 'fig');
            end
        end
    end
    close(brainData);
    
    currentData = meanCorrData.Data.(channel)(:, :, slicesToPlot, idsShifts);

    % Mask the correlation data using the Colin mask
    for b = 1:size(currentData, 4)
        temp = currentData(:, :, :, b);
        temp(colinMask == 0) = NaN;
        currentData(:, :, :, b) = temp;
    end
    clear temp;
    
    % Crop the correlation images
    currentData(1:pixelCrop, :, :, :) = [];
    currentData(end-pixelCrop:end, :, :, :) = [];
    currentData(:, 1:pixelCrop, :, :) = [];
    currentData(:, end-pixelCrop:end, :, :) = [];

    % Create the montage
    brainData = brainPlot(...
        'mri',...
        currentData,...
        'AxesColor', 'k',...
        'CLim', [-3 3],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'Title', ['BOLD-' channel],...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', shiftsToPlot,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slicesToPlot);

    % Adjust some properties
    set(brainData.Axes.Primary, 'Color', 'k');
    set(brainData.Axes.Primary, 'FontSize', 20);
    set(get(brainData.Colorbar, 'YLabel'), 'FontSize', 25);
    
    imSaveName = [dataSaveName sprintf(avgAnalysisStamp, channel)];
    
    saveas(brainData.FigureHandle, [imSaveName '.png'], 'png');
    saveas(brainData.FigureHandle, [imSaveName '.fig'], 'fig');
    
    close(brainData);
end



%% 1031 - Imaging Thresholded Average BOLD-EEG Partial Correlations (Excluding Subjects 5 & 6)
% Today's parameters
timeStamp = '201408261031';
avgAnalysisStamp = 'BOLD-%s Thresholded Average Partial Correlation';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140826/201408261031 - ';

slicesToPlot = 48:4:64;
shiftsToPlot = -20:2:20;
pixelCrop = 7;

% Load the Colin brain in order to use its brain mask (removes a lot of edge-of-brain junk)
load('Special Functions/@brainViewer/colinBrain.mat');
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

colinBrain(1:pixelCrop, :, :) = [];
colinBrain(end-pixelCrop:end, :, :) = [];
colinBrain(:, 1:pixelCrop, :) = [];
colinBrain(:, end-pixelCrop:end, :) = [];

corrPath = [get(Paths, 'Desktop') '/Data Sets/Data Objects/Partial Correlation/BOLD-EEG'];
corrFiles = search(corrPath, '^partialCorrObject.*20140416');
meanCorrFiles = search(corrPath, 'meanPartialCorrObject.*20131126');

for a = 1:length(corrFiles)
    
    load(corrFiles{a});
    
    corrData(1).Parameters.Correlation.Subjects(5:6) = [];
    meanCorrData = mean(corrData);
    
    channel = meanCorrData.Parameters.Correlation.Channels{1};
    idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
    currentData = meanCorrData.Data.(channel)(:, :, slicesToPlot, idsShifts);
    
    temp = load(meanCorrFiles{a});
    cutoffs = temp.meanCorrData.Parameters.SignificanceCutoffs.(channel);

    % Mask the correlation data using the Colin mask
    for b = 1:size(currentData, 4)
        temp = currentData(:, :, :, b);
        temp(colinMask == 0) = NaN;
        currentData(:, :, :, b) = temp;
    end
    clear temp;
    
    currentData(currentData > cutoffs(1) & currentData < cutoffs(2)) = NaN;
    
    % Crop the correlation images
    currentData(1:pixelCrop, :, :, :) = [];
    currentData(end-pixelCrop:end, :, :, :) = [];
    currentData(:, 1:pixelCrop, :, :) = [];
    currentData(:, end-pixelCrop:end, :, :) = [];

    % Create the montage
    brainData = brainPlot(...
        'mri',...
        currentData,...
        'Anatomical', colinBrain,...
        'AxesColor', 'k',...
        'CLim', [-3 3],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'Title', ['BOLD-' channel],...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', shiftsToPlot,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slicesToPlot);

    % Adjust some properties
    set(brainData.Axes.Primary, 'Color', 'k');
    set(brainData.Axes.Primary, 'FontSize', 20);
    set(get(brainData.Colorbar, 'YLabel'), 'FontSize', 25);
    
    imSaveName = [dataSaveName sprintf(avgAnalysisStamp, channel)];
    
    saveas(brainData.FigureHandle, [imSaveName '.png'], 'png');
    saveas(brainData.FigureHandle, [imSaveName '.fig'], 'fig');
    
    close(brainData);
end



%% 1310 - 
% Today's parameters
timeStamp = '201408261310';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140826/201408261310 - ';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject');






