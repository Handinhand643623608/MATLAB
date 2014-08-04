%% 20140411

% TODO - Brighten up the Colin Brain (or adjust it somehow) so it doesn't drown out the data


%% 1343 - Adjusting BOLD-EEG Partial Correlation Images
% These need a lot of help before going into the publication. Going to try several combinations of
% layouts to see how they look & if they still contain enough info to support the points made in the
% paper.
load masterStructs;
corrFiles = get(fileData([fileStruct.Paths.Desktop '/Partial Correlation']), 'Path');
slicesToPlot = 48:8:64;
shiftsToPlot = -20:4:20;

% Load the Colin Brain to use as an underlay image
load([fileStruct.Paths.Main '/Special Functions/@brainViewer/colinBrain.mat']);
colinBrain = colinBrain(:, :, slicesToPlot);

% Load the first file for now to mess around with the layout some
load(corrFiles{1});
idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
cutoffs = meanCorrData.Parameters.SignificanceCutoffs.AF7;
currentData = meanCorrData.Data.AF7(:, :, slicesToPlot, idsShifts);
currentData(currentData > cutoffs(1) & currentData < cutoffs(2)) = NaN;

% Create the montage
brainData = brainPlot(...
    'mri',...
    currentData,...
    'Anatomical', colinBrain,...
    'AxesColor', 'k',...
    'CLim', [-3 3],...
    'Color', 'w',...
    'ColorbarLabel', 'Z-Scores',...
    'Title', 'BOLD-AF7',...
    'XLabel', 'Time Shift (s)',...
    'XTickLabel', shiftsToPlot,...
    'YLabel', 'Slice Number',...
    'YTickLabel', slicesToPlot);

% Adjust some properties
set(brainData.Axes.Primary, 'Color', 'k');
set(brainData.Axes.Primary, 'FontSize', 20);
set(get(brainData.Colorbar, 'YLabel'), 'FontSize', 25);


%% 1413 - Generating New Images for Each BOLD-EEG Correlation
% Initialize formatting variables
cle;
load masterStructs;
corrFiles = get(fileData([fileStruct.Paths.Desktop '/Partial Correlation']), 'Path');
slicesToPlot = 48:4:64;
shiftsToPlot = -20:4:20;
pixelCrop = 7;

% Load the Colin Brain to use as an underlay image
load([fileStruct.Paths.Main '/Special Functions/@brainViewer/colinBrain.mat']);
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

% % structEl = strel('octagon', 3);
% structEl = strel('diamond', 2);
% colinMask = imerode(colinMask, structEl);

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

% a = 1;
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
    brainData(a) = brainPlot(...
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
    set(brainData(a).Axes.Primary, 'Color', 'k');
    set(brainData(a).Axes.Primary, 'FontSize', 20);
    set(get(brainData(a).Colorbar, 'YLabel'), 'FontSize', 25);
    
    saveas(brainData(a).FigureHandle, [fileStruct.Paths.Desktop '/' channel '.png'], 'png')
    saveas(brainData(a).FigureHandle, [fileStruct.Paths.Desktop '/' channel '.fig'], 'fig')
end

    

%%
eegMap({'AF7', 'FPZ', 'C3', 'PO8', 'PO10'})
    