%% 20140505 


%% 0952 - Making a Movie of EEG Synchronization over Time for Subject 8 Scan 2
% Going to be shown at the lab meeting today.
subject = 8;
scan = 2;
load([fileStruct.Paths.Desktop '/swcData_EEG_(9, 0, 10)_20140428T1228.mat']);

currentCorr = corrData(subject, scan).Data;

savePath = [fileStruct.Paths.Desktop '/Temp Sync Movie'];
if ~exist(savePath, 'dir'); mkdir(savePath); end;

for a = 1:size(currentCorr, 3)
    figure('Visible', 'off'); 
    imagesc(currentCorr(:, :, a), [-1 1]);
    axis square;
    saveas(gcf, [savePath '/' num2str(a) '.png'], 'png');
    close;
end


%% 1005 - Making a Montage of SWPC between FPz-BOLD for Subject 8 Scan 2
% Sliding window partial correlation from single subject to be shown at the lab meeting today.
load slidingWindowPartialCorr_FPZ_(20, 19)_20140421.mat;

scan = 16;
slicesToPlot = 52:4:60;
timesToPlot = 1:4:180;
timeStr = [num2str(timesToPlot(1)) ' - ' num2str(timesToPlot(end))];

brainData = brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, scan),...
    'Title', ['Scan' num2str(scan) ' Times ' timeStr],...
    'XTickLabel', (timesToPlot)*2,...
    'XLabel', 'Time (s)',...
    'YTickLabel', slicesToPlot,...
    'YLabel', 'Slice Number');


%% 1333
if ~exist('boldData', 'var')
    load boldObject-8_RS_dcZ_20131030;
end

maxNumClusters = 50;

funData = boldData(2).Data.Functional;
dFunData = diff(funData, 1, 4);
dFunData = zscore(dFunData, [], 4);

dFunData = reshape(dFunData, [], 217);
idsMask = isnan(dFunData(:, 1));
dFunData(idsMask, :) = [];


clusterData = kmeans(dFunData', maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');


%% 1354

ids1 = [(clusterData == 29)' false];
brainData = brainPlot('mri', funData(:, :, 48:4:64, ids1));

ids1Shift = circshift(ids1, [0 1]);
brainData = brainPlot('mri', funData(:, :, 48:4:64, ids1Shift));


%%
if ~exist('boldData', 'var')
    load boldObject-8_RS_dcZ_20131030;
end

maxNumClusters = 30;

funData = boldData(2).Data.Functional;

temp = reshape(funData, [], 218);
idsMask = isnan(temp(:, 1));
temp(idsMask, :) = [];


clusterData = kmeans(temp', maxNumClusters, 'Distance', 'correlation', 'EmptyAction', 'drop');


%%

ids1 = (clusterData == 29)';
brainData = brainPlot('mri', funData(:, :, 48:4:64, ids1));


%%
allAverage = [];
for a = 1:maxNumClusters
    currentAverage = nanmean(funData(:, :, 48:4:64, clusterData == a), 4);
    allAverage = cat(4, allAverage, currentAverage);
end

brainData = brainPlot('mri', allAverage, 'CLim', [-3 3]);


%% 1431

funData = boldData(2).Data.Functional;
vFunData = funData.^2;
% sFunData = sum(vFunData, 4);
sFunData = nanmean(vFunData, 4);

brainData = brainPlot('mri', sFunData(:, :, 40:4:64));
brainData = brainPlot('mri', vFunData(:, :, 40:4:64, 1:10:end), 'CLim', [0 2.5]);