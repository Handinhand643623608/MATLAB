%% 20140423


%% 1440 - Re-Imaging BOLD-Global Partial Correlations
% Needs to be done so they match the formatting of all other correlation mappings.

% Initialize formatting variables
cle;
load masterStructs;
searchPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-Global/'];
corrFiles = get(fileData(searchPath), 'Path');
slicesToPlot = 48:4:64;
shiftsToPlot = -20:4:20;
pixelCrop = 7;

% Load the Colin brain in order to use its brain mask (removes a lot of edge-of-brain junk)
load([fileStruct.Paths.Main '/Special Functions/@brainViewer/colinBrain.mat']);
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

% a = 1;
for a = 1:length(corrFiles)
    % Load the correlation data & pull important parameters from the data object
    load(corrFiles{a});
    idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
    currentData = meanCorrData.Data.Global(:, :, slicesToPlot, idsShifts);

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
    brainData(a) = brainPlot(...
        'mri',...
        currentData,...
        'AxesColor', 'k',...
        'CLim', [-3 3],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', shiftsToPlot,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slicesToPlot);

    % Adjust some properties
    set(brainData(a).Axes.Primary, 'Color', 'k');
    set(brainData(a).Axes.Primary, 'FontSize', 20);
    set(get(brainData(a).Colorbar, 'YLabel'), 'FontSize', 25);
    
    % Save the images
    saveStr = '(PreGSR)';
    if any(strcmpi(meanCorrData.Parameters.Correlation.Control, 'global')); saveStr = '(PostGSR)'; end;
    saveas(brainData(a).FigureHandle, [fileStruct.Paths.Desktop '/BOLD-Global ' saveStr '.png'], 'png')
    saveas(brainData(a).FigureHandle, [fileStruct.Paths.Desktop '/BOLD-Global ' saveStr '.fig'], 'fig')
end


%% 1519 - Messing Around with 2D Image Correlation
% Probably useful for pattern recognition. Using subject 1 scan 1 BOLD data.
slicesToUse = 48:4:64;
funData = boldData(1).Data.Functional(:, :, slicesToUse, :);
funData(isnan(funData)) = 0;
corrMat = zeros(size(funData, 4), size(funData, 4), size(funData, 3));

% Across slices, correlate each time point image with all other images
for a = 1:size(funData, 4)
    for b = a:size(funData, 4)
        for c = 1:size(funData, 3)
            corrMat(a, b, c) = corr2(funData(:, :, c, a), funData(:, :, c, b));
            corrMat(b, a, c) = corrMat(a, b, c);
        end
    end
end

% Display the time point correlation matrix
for a = 1:size(corrMat, 3)
    figure; 
    imagesc(corrMat(:, :, a));
    title(['Slice ' num2str(slicesToUse(a))]);
end

% Results: nothing surprising. Time points close to one another tend to correlate well enough. The
% time points in the middle of the scan don't follow this trend as well as the beginning/end,
% though. Correlation values vary between about -0.7:0.7, plus or minus.


%% 1539 - Identifying Which Time Points Correlate Most Often with Others
% 
posCorr = corrMat > 0.5;
numPosCorr = sum(posCorr, 1);
idsMax = zeros(size(numPosCorr));

% Get logical indices for the time point that correlates highly with others most often
for a = 1:size(numPosCorr, 3)
    idsMax(1, :, a) = numPosCorr(1, :, a) == max(numPosCorr(1, :, a));
end

% Examine each slice at this time point
idsMax = logical(idsMax);
for a = 1:size(idsMax, 3)
    figure;
    imagesc(funData(:, :, a, idsMax(1, :, a)));
end

% Average together the other time points that correlate highly with this one
highCorrSlices = zeros(size(funData, 1), size(funData, 2), size(idsMax, 3));
for a = 1:size(idsMax, 3)
    currentSlice = squeeze(funData(:, :, a, :));
    timePoints = posCorr(:, idsMax(:, :, a));
    highCorrSeries = funData(:, :, a, timePoints);
    highCorrSlices(:, :, a) = nanmean(highCorrSeries, 4);
    figure;
    imagesc(highCorrSlices(:, :, a), [-0.5 0.5]);
end

% Results: these don't look like much. Large portions of the brain are filled in red, indicating
% that a great deal of activity is strongly correlated. Removing the global signal (and other
% nuisance signals while I'm at it) would probably help.


%% 1618 - Trying The Above Correlations Again After Regressing Nuisance Signals

if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

slicesToUse = 48:4:64;
funData = boldData(1).Data.Functional(:, :, slicesToUse, :);
corrMat = zeros(size(funData, 4), size(funData, 4), size(funData, 3));

% Regress nuisance signals
funData = reshape(funData, [], size(funData, 4));
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];

nuisanceSigs = [ones(size(corrMat, 1), 1), boldData(1).Data.Nuisance.Motion', boldData(1).Data.Nuisance.Global', boldData(1).Data.Nuisance.WM', boldData(1).Data.Nuisance.CSF'];
regFunData = (funData' - nuisanceSigs*(nuisanceSigs\funData'))';

funData = zeros(length(idsMask), size(regFunData, 2));
funData(~idsMask, :) = regFunData;
funData = reshape(funData, 91, 109, length(slicesToUse), 218);

% Across slices, correlate each time point image with all other images
for a = 1:size(funData, 4)
    for b = a:size(funData, 4)
        for c = 1:size(funData, 3)
            corrMat(a, b, c) = corr2(funData(:, :, c, a), funData(:, :, c, b));
            corrMat(b, a, c) = corrMat(a, b, c);
        end
    end
end

posCorr = corrMat > 0.5;
numPosCorr = sum(posCorr, 1);

% Average together the other time points that correlate highly with this one
highCorrSlices = zeros(size(funData, 1), size(funData, 2), size(funData, 3));
for a = 1:length(slicesToUse)
    idsMax = numPosCorr(1, :, a) == max(numPosCorr(1, :, a));
    currentSlice = squeeze(funData(:, :, a, :));
    timePoints = posCorr(:, find(idsMax, 1), a);
    highCorrSeries = funData(:, :, a, timePoints);
    highCorrSlices(:, :, a) = nanmean(highCorrSeries, 4);
    figure;
    imagesc(highCorrSlices(:, :, a), [-0.5 0.5]);
end

% Results: these averages contain much more focal regional activity. The patterns themselves still
% don't look like much to me, as they could contain any number of RSNs.



%% 1705
movieData = boldData(1).Data.Functional(:, :, 50, :);
movieData(isnan(movieData)) = 0;
minVal = min(movieData(:));
maxVal = max(movieData(:));
cmap = jet(256);
movieData = ((length(cmap)- 1)*(movieData - minVal)/(maxVal - minVal)) + 1;

brainMovie = immovie(movieData, cmap);
implay(brainMovie);


%% 1728 - Spatial Clustering of Single-Subject BOLD Data
slicesToPlot = 48:4:64;
funData = boldData(1).Data.Functional(:, :, slicesToPlot, :);

funData = reshape(funData, [], 218);
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];
funData(isnan(funData)) = 0;

idsCluster = kmeans(funData, 10, 'Distance', 'correlation', 'EmptyAction', 'drop');

clusterData = nan(length(idsMask), 1);
clusterData(~idsMask) = idsCluster;
clusterData = reshape(clusterData, 91, 109, length(slicesToPlot));

brainData = brainPlot('mri', clusterData, 'CLim', [1 10]);


%% 1755 - Temporal Clustering of Single-Subject BOLD Data
slicesToPlot = 48:4:64;
maxNumClusters = 10;

funData = boldData(1).Data.Functional(:, :, slicesToPlot, :);
funData = reshape(funData, [], 218);
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];
funData(isnan(funData)) = 0;

idsCluster = kmeans(funData', maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');

figure;
hist(idsCluster, maxNumClusters);
idsToCheck = idsCluster == mode(idsCluster);

dataToPlot = boldData(1).Data.Functional(:, :, slicesToPlot, idsToCheck);
brainData = brainPlot('mri', dataToPlot);

dataArray = nan(91, 109, length(slicesToPlot), maxNumClusters);
for a = 1:maxNumClusters
    
    idsCurrentCluster = idsCluster == a;
    if ~any(idsCurrentCluster); continue; end;
    
    currentData = boldData(1).Data.Functional(:, :, slicesToPlot, idsCurrentCluster);
    currentData = nanmean(currentData, 4);
    
    dataArray(:, :, :, a) = currentData; 
end

brainData(2) = brainPlot('mri', dataArray);


%% 1814 - Temporal Clustering of BOLD Data Derivatives (with Respect to Time)
slicesToPlot = 48:4:64;
maxNumClusters = 10;

funData = boldData(1).Data.Functional(:, :, slicesToPlot, :);
funData = reshape(funData, [], 218);
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];
funData(isnan(funData)) = 0;

funData = diff(funData, 1, 2);

funData(funData < 0) = -1;
funData(funData > 0) = 1;

idsCluster = kmeans(funData', maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');

figure;
hist(idsCluster, maxNumClusters);
idsToCheck = idsCluster == mode(idsCluster);

dataToPlot = boldData(1).Data.Functional(:, :, slicesToPlot, idsToCheck);
brainData = brainPlot('mri', dataToPlot);

dataArray = nan(91, 109, length(slicesToPlot), maxNumClusters);
for a = 1:maxNumClusters
    idsCurrentCluster = idsCluster == a;
    if ~any(idsCurrentCluster); continue; end;
    
    currentData = boldData(1).Data.Functional(:, :, slicesToPlot, idsCurrentCluster);
    currentData = nanmean(currentData, 4);
    
    dataArray(:, :, :, a) = currentData; 
end

brainData(2) = brainPlot('mri', dataArray);


%% 1818 - Spatial Clustering of BOLD Data Derivatives (with Respect to Time)
slicesToPlot = 48:4:64;
maxNumClusters = 5;

funData = boldData(1).Data.Functional(:, :, slicesToPlot, :);
funData = reshape(funData, [], 218);
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];

funData = diff(funData, 1, 2);

funData(funData < 0) = -1;
funData(funData > 0) = 1;

idsCluster = kmeans(funData, maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');

clusterData = nan(length(idsMask), 1);
clusterData(~idsMask) = idsCluster;
clusterData = reshape(clusterData, 91, 109, length(slicesToPlot));

brainData = brainPlot('mri', clusterData, 'CLim', [1 maxNumClusters]);