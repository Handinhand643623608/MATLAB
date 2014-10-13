%% 20140501 


%% 1215 - Generating Movies of Concurrent fMRI & EEG Infraslow Activity
% If I could compare the activities of both EEG and BOLD simultaneously by eye, I might be able to
% pick up patterns like QPPs or anything else of that nature that really sticks out. However, for
% now the primary objective is to see what's happening in the BOLD data at times around when EEG
% synchronization is high. I'll try first to look to high activity magnitudes occuring in many
% electrodes simultaneously, then move around nearby frames to see how the BOLD data is behaving.

load eegObject-1_RS_dcZ_20130906;
if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

% Flatten the functional data
funData = boldData(1).Data.Functional(:, :, 48:4:64, :);
funData = permute(funData, [2 3 1 4]);
funData = flipdim(reshape(funData, [], 91, 218), 1);

% Get the EEG data
ephysData = eegData(1).Data.EEG;

% Set up axes to plot both the functional & e-phys data
window = windowObj('Size', 'fullscreen', 'Units', 'normalized');
window.Axes.BOLD = axes(...
    'Box', 'off',...
    'Color', 'none',...
    'Position', [0.2, 0.1, 0.1, 0.8],...
    'XTick', [],...
    'YTick', []);
window.Axes.EEG = axes(...
    'Box', 'off',...
    'Color', 'none',...
    'Position', [0.6, 0.4, 0.2, 0.3],...
    'XTick', [],...
    'YTick', []);

% Plot the activity at each time point for both modalities
set(window, 'Visible', 'off');
pbar = progress('Making Movie');
for a = 1:218
    imagesc(funData(:, :, a), 'Parent', window.Axes.BOLD);
    boldFrames(a) = getframe(window.Axes.BOLD);
    eegMap(ephysData(:, a), 'Labels', 'off', 'ParentAxes', window.Axes.EEG);
    eegFrames(a) = getframe(window.Axes.EEG);
    update(pbar, a/218);
end
close(pbar);
close(window);


%% 1343 - Making Movies Using the Method Above isn't Working. Writing to Images Instead
% Going to have to use a separate program to make the movies (probably Windows Movie Maker).

load masterStructs
load eegObject-1_RS_dcZ_20130906;
if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

% Get & flatten the functional data
funData = boldData(1).Data.Functional(:, :, 48:4:64, :);
funData = permute(funData, [2 3 1 4]);
funData = flipdim(reshape(funData, [], 91, 218), 1);

% Get the e-phys data
ephysData = eegData(1).Data.EEG;

% Set up axes to plot both functional & ephys data on the same plot
window = windowObj('Size', 'fullscreen', 'Units', 'normalized');
window.Axes.BOLD = axes(...
    'Box', 'off',...
    'Color', 'none',...
    'Position', [0.2, 0.1, 0.1, 0.8],...
    'XTick', [],...
    'YTick', []);
window.Axes.EEG = axes(...
    'Box', 'off',...
    'Color', 'none',...
    'Position', [0.6, 0.4, 0.2, 0.3],...
    'XTick', [],...
    'YTick', []);

% Set up a directory for storing the images
saveDir = [fileStruct.Paths.Desktop '/Activity Images'];
if ~exist(saveDir, 'dir'); mkdir(saveDir); end;

% Image the activity at each time point for both modalities
set(window, 'Visible', 'off');
pbar = progress('Making Movie');
for a = 1:218
    imagesc(funData(:, :, a), 'Parent', window.Axes.BOLD);
    eegMap(ephysData(:, a), 'Labels', 'off', 'ParentAxes', window.Axes.EEG);
    saveas(window.FigureHandle, [saveDir '/' num2str(a) '.png'], 'png');
    update(pbar, a/218);
end
close(pbar);
close(window);


% Results: This worked, but recognizing patterns through visual inspection alone seems like an
% improbable feat. There's just too much going on. Also, this takes ~30 minutes to generate a movie
% of a single scan. After watching the movie a couple of times, nothing obvious is happening in the
% BOLD signal at times around high & large-scale EEG activity. Could be because subject 1 isn't the
% ideal subject for this sort of analysis, or because there's nothing to observe. Creating other
% movies is too time-consuming for now, though, with the rsFC abstract due tomorrow.
%
% I need some kind of algorithm to help investigate this.


%% 1450 - Stationary Correlation between BOLD & EEG Global Signals (not the Cluster Signal)
% Going to see how grand-mean global signals compare to one another between modalities. I had tried
% this once in the distant past, I remember, but those results are likely very far out of date. This
% analysis will use the global average of EEG signals instead of the five cluster signals (as was 
% used two days ago: 20140428 @ 1424)

load eegObject-1_RS_dcZ_20130906;
if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

ephysData = zscore(nanmean(eegData(1).Data.EEG, 1));
funData = zscore(boldData(1).Data.Nuisance.Global);
[corr, lags] = xcorr(funData, ephysData, 10, 'coeff');
figure; plot(lags.*2, corr);

figure; plot(1:218, funData, 1:218, ephysData);

[corr2, lags2] = xcorr(diff(funData), diff(ephysData), 10, 'coeff');
figure; plot(lags2*2, corr2);
figure; plot(1:217, diff(funData), 1:217, diff(ephysData));

% Results: This looks promising. For at least this subject the signals are obviously well
% correlated. Maximum correlation is ~0.4 and occurs at a time lag of ~8 seconds. Visual inspection
% of the two signals also strongly suggests a relationship between them. Correlating the derivatives
% of each signal doesn't reveal anything new. Need to see if this result is common to other
% subjects.


%% 1521 - Repeating the Last Analysis for All Subjects & Scans
% Let's see how this looks on average & across individuals. 
load masterStructs;
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', 'dcZ'), 'Path');
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ_'), 'Path');

corrData(8, 3) = struct('Data', [], 'Lags', []);

pbar = progress('Correlating', 'Scans');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    
    reset(pbar, 2);
    for b = 1:length(boldData)
        funData = zscore(boldData(b).Data.Nuisance.Global);
        ephysData = zscore(nanmean(eegData(b).Data.EEG, 1));
        
        [currentCorr, lags] = xcorr(funData, ephysData, 10, 'coeff');
        
        corrData(a, b).Data = currentCorr;
        corrData(a, b).Lags = 2*lags;
        update(pbar, 2, b/length(boldData));
    end
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);

save([fileStruct.Paths.Desktop '/corrData_GS-GS_20140501T1521.mat'], 'corrData', '-v7.3');


%% 1554 - Plotting BOLD-EEG Global Signal Correlations from Above

figure;
catCorr = [];
c = 1;
for a = 1:size(corrData, 1)
    for b = 1:size(corrData, 2)
        if ~isempty(corrData(a, b).Data)
            subplot(4, 5, c);
            plot(corrData(a, b).Lags, corrData(a, b).Data);
            c = c + 1;
            
            catCorr = cat(1, catCorr, corrData(a, b).Data);
        end
    end
end

meanCorr = mean(catCorr, 1);
figure; plot(corrData(1, 1).Lags, meanCorr);

% Results: Highly disappointing. The strong association between the signals seen in both of Subject
% 1's scans is not at all well-replicated across individuals.
%
% The strength of the correlation is quite variable across both individuals and scans of the same
% individual, although the specific time shifts where peaks occur is sort of preserved in scans of
% any individual. The time lags of maximum positive/negative correlation appear to follow no
% particular trend across individuals.
%
% Consequently, the average across all scans exhibits a very broad peak at ~4 seconds time shift
% (EEG predicting BOLD) with a maximum correlation value of ~0.1. Given the strength and consistency
% of results from other correlation analyses, I'd expect nothing from this to pass significance
% testing. 
%
% Dead end.


%% 1701 - 
slicesToPlot = 48:4:64;
maxNumClusters = 5;

load eegObject-1_RS_dcZ_20130906;
if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

funData = boldData(1).Data.Functional(:, :, slicesToPlot, :);
ephysData = eegData(1).Data.EEG;

funData = reshape(funData, [], 218);
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];
funData(isnan(funData)) = 0;

idsNanEEG = isnan(ephysData(:, 1));
ephysData(idsNanEEG, :) = [];
numElectrodes = size(ephysData, 1);

allData = [funData; ephysData];
idsCluster = kmeans(allData, maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');

clusterEEG = idsCluster(end-(numElectrodes - 1):end);
idsCluster(end-(numElectrodes-1):end) = [];

clusterEEG = cat(1, clusterEEG, nan(68-numElectrodes, 1));

clusterData = nan(length(idsMask), 1);
clusterData(~idsMask) = idsCluster;
clusterData = reshape(clusterData, 91, 109, length(slicesToPlot));

brainData = brainPlot('mri', clusterData, 'CLim', [1 maxNumClusters]);

eegPlot = eegMap(clusterEEG);
set(eegPlot, 'Color', 'k');
set(eegPlot.Axes, 'Color', 'k');


%% 1727 - 
slicesToPlot = 48:4:64;
maxNumClusters = 10;

load eegObject-1_RS_dcZ_20130906;
if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

funData = boldData(1).Data.Functional(:, :, slicesToPlot, :);
ephysData = eegData(1).Data.EEG;

funData = reshape(funData, [], 218);
idsMask = isnan(funData(:, 1));
funData(idsMask, :) = [];
funData(isnan(funData)) = 0;

idsNanEEG = isnan(ephysData(:, 1));
ephysData(idsNanEEG, :) = [];
numElectrodes = size(ephysData, 1);


% funData = diff(funData, 1, 2);
% 
% funData(funData < 0) = -1;
% funData(funData > 0) = 1;

allData = [funData; ephysData];
idsCluster = kmeans(funData', maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');

figure;
hist(idsCluster, maxNumClusters);
idsToCheck = idsCluster == mode(idsCluster);

clusterEEG = idsCluster(end-(numElectrodes - 1):end);
idsCluster(end-(numElectrodes-1):end) = [];

clusterEEG = cat(1, clusterEEG, nan(68-numElectrodes, 1));

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