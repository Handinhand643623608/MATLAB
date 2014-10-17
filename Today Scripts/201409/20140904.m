%% 20140904 


%% 1437 - Remaking Plots of Previous Thresholded BOLD-EEG Correlations for rsFC Poster
% Code below was copied from 20140411 today script

% Today's parameters
timeStamp = '201409041437';
analysisStamp = 'Old BOLD-%s Thresholded Averaged Cross Correlation';
savePath = 'C:/Users/jgrooms/Desktop/Today Data/20140904';
dataSaveName = '201409041437 - %s';

corrPath = 'C:\Users\jgrooms\Desktop\Data Sets\Data Objects\Partial Correlation\BOLD-EEG';
corrFiles = search(corrPath, 'meanPartialCorrObject.*20131126');

% Initialize formatting variables
slicesToPlot = 48:4:64;
shiftsToPlot = 0:4:20;
pixelCrop = 7;

% Load the Colin Brain to use as an underlay image
load([where('boldObj.m') '/colinBrain.mat']);
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

% Mask out the skull & do a histogram adjustment 
% This brightens up the anatomical data. Values used are from examining the histogram of data
colinBrain(colinMask == 0) = 0;
colinBrain(colinBrain > 5e6) = 4.5e6;                               % <-- Remove high intensity outlier voxels
colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;  % <-- Increase intensity of these data (gray & white matter)

% Crop the anatomical underlay image (makes the montage images look larger)
colinBrain(1:pixelCrop, :, :) = [];
colinBrain(end-pixelCrop:end, :, :) = [];
colinBrain(:, 1:pixelCrop, :) = [];
colinBrain(:, end-pixelCrop:end, :) = [];

for a = 1:length(corrFiles)
    % Load the correlation data & pull important parameters from the data object
    load(corrFiles{a});
    channel = meanCorrData.Parameters.Correlation.Channels{1};
    cutoffs = meanCorrData.Parameters.SignificanceCutoffs.(channel);
    idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
    currentData = meanCorrData.Data.(channel)(:, :, slicesToPlot, idsShifts);
    
    % Mask the correlation data using the colin mask (works great for removing edge-of-brain noise)
    for b = 1:size(currentData, 4)
        temp = currentData(:, :, :, b);        
        temp(colinMask == 0) = 0;
        currentData(:, :, :, b) = temp;
    end
    clear temp;
    
    % Apply significance thresholds
    currentData(currentData > cutoffs(1) & currentData < cutoffs(2)) = NaN;

    % Crop the correlation images to the same size as the new anatomical ones
    currentData(1:pixelCrop, :, :, :) = [];
    currentData(end-pixelCrop:end, :, :, :) = [];
    currentData(:, 1:pixelCrop, :, :) = [];
    currentData(:, end-pixelCrop:end, :, :) = [];
    
    % Create the montage
    brainData(a) = BrainPlot(...
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
    set(brainData(a).Axes.Primary, 'Color', 'k');
    set(brainData(a).Axes.Primary, 'FontSize', 20);
    set(get(brainData(a).Colorbar, 'YLabel'), 'FontSize', 25);
    
    currentSaveName = sprintf(dataSaveName, sprintf(analysisStamp, channel));
    brainData(a).Store('Path', savePath, 'Name', currentSaveName, 'Ext', {'png', 'fig'}, 'Overwrite', true);
    
end
brainData.close;
