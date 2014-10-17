%% 20140923 


%% 1303 - Remaking Unthresholded BOLD-EEG Correlation Images for BIONIC Presentation
% Today's parameters
timeStamp = '201409231303';
analysisStamp = 'Old BOLD-%s Unthresholded Averaged Cross Correlation';
savePath = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140923';
dataSaveName = '201409231303 - %s'

corrPath = 'E:\Graduate Studies\Lab Work\Data Sets\Data Objects\Partial Correlation\BOLD-EEG';
corrFiles = search(corrPath, 'meanPartialCorrObject.*dcZ.*20131126');

% Initialize formatting variables
slicesToPlot = 48:4:64;
shiftsToPlot = 0:4:20;
pixelCrop = 7;

% Load the Colin Brain to use as an underlay image
load([where('boldObj.m') '/colinBrain.mat']);
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

for a = 1:length(corrFiles)
    % Load the correlation data & pull important parameters from the data object
    load(corrFiles{a});
    channel = meanCorrData.Parameters.Correlation.Channels{1};
    idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
    currentData = meanCorrData.Data.(channel)(:, :, slicesToPlot, idsShifts);

    % Mask the correlation data using the colin mask (works great for removing edge-of-brain noise)
    for b = 1:size(currentData, 4)
        temp = currentData(:, :, :, b);        
        temp(colinMask == 0) = 0;
        currentData(:, :, :, b) = temp;
    end
    clear temp;
    
    currentData(currentData == 0) = NaN;
    
    % Crop the correlation images to the same size as the new anatomical ones
    currentData(1:pixelCrop, :, :, :) = [];
    currentData(end-pixelCrop:end, :, :, :) = [];
    currentData(:, 1:pixelCrop, :, :) = [];
    currentData(:, end-pixelCrop:end, :, :) = [];
    
    % Create the montage
    brainData(a) = BrainPlot(...
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
    set(brainData(a).Axes.Primary, 'Color', 'k');
    set(brainData(a).Axes.Primary, 'FontSize', 20);
    set(get(brainData(a).Colorbar, 'YLabel'), 'FontSize', 25);
    
    currentSaveName = sprintf(dataSaveName, sprintf(analysisStamp, channel));
    brainData(a).Store('Path', savePath, 'Name', currentSaveName, 'Ext', {'png', 'fig'}, 'Overwrite', true);
    
end
brainData.close;
