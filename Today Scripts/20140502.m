%% 20140502


%% 1208 - Making Plots for rsFC Abstract
% Plotting EEG synchronization (20s windows, 18s overlap)
figure; 
plot(syncData(8, 2).CorrelationMeans, 'LineWidth', 2);
set(gca,...
    'FontSize', 20,...
    'XLim', [0 200],...
    'XTickLabel', 0:40:400);
ylabel('Z-Scores', 'FontSize', 25);
xlabel('Time (s)', 'FontSize', 25);


saveas(gcf, [fileStruct.Paths.Desktop '/S8-2 EEG Synchronization.png'], 'png');


%% 1214

figure; imagesc(currentCorr(:, :, 88), [-3 3])
axis square;
set(gca, 'FontSize', 20);
cbar1 = colorbar;
set(cbar1,...
    'FontSize', 20,...
    'YTick', -3:1:3);
set(get(cbar1, 'YLabel'),...
    'String', 'Z-Scores',...
    'FontSize', 25);
% saveas(gcf, [fileStruct.Paths.Desktop '/S8-2 EEG Synchronized.png'], 'png');


figure; imagesc(currentCorr(:, :, 109), [-3 3])
axis square;
set(gca, 'FontSize', 40);
cbar2 = colorbar;
set(cbar2,...
    'FontSize', 40,...
    'YTick', [-3:3:3]);
set(get(cbar2, 'YLabel'),...
    'String', 'Z-Scores',...
    'FontSize', 50);
% saveas(gcf, [fileStruct.Paths.Desktop '/S8-2 EEG Unsynchronized.png'], 'png');



%% 1649 
subject = 17;

brainPlot('mri', corrData(:,:, 48:4:64, 1:10:end, subject), 'Title', ['Subject ' num2str(subject)]);



%%
scan = 16;
slicesToPlot = 52:4:60;
startTime = 141;
timeStep = 2;
timeStr = [num2str(timesToPlot(1)) ' - ' num2str(timesToPlot(end))];

% timesToPlot = startTime:timeStep:startTime + timeStep*20;
timesToPlot = startTime:timeStep:startTime + 30;

brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, scan),...
    'Title', ['Scan' num2str(scan) ' Times ' timeStr],...
    'XTickLabel', timesToPlot*2,...
    'XLabel', 'Time (s)',...
    'YTickLabel', slicesToPlot,...
    'YLabel', 'Slice Number');



%%
scan = 16;
slicesToPlot = 52:4:60;
timesToPlot = [62 132 302]./2;
brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, scan),...
    'Title', ['Scan' num2str(scan) ' Times ' timeStr],...
    'XTickLabel', (timesToPlot)*2,...
    'XLabel', 'Time (s)',...
    'YTickLabel', slicesToPlot,...
    'YLabel', 'Slice Number');



%%
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

%%
for a = 1:17
    brainPlot('mri', corrData(:, :, slicesToPlot, 1:5:end, a),...
    'Title', ['Scan' num2str(a) ' Times ' timeStr],...
    'XTickLabel', (1:5:180)*2,...
    'XLabel', 'Time (s)',...
    'YTickLabel', slicesToPlot,...
    'YLabel', 'Slice Number');
end




%%
scan = 16;
slicesToPlot = 52:4:60;
timesToPlot = [62 132 302]./2;
pixelCrop = 7;

% Crop the correlation images
currentData = corrData(:, :, slicesToPlot, timesToPlot, scan);
currentData(1:pixelCrop, :, :, :) = [];
currentData(end-pixelCrop:end, :, :, :) = [];
currentData(:, 1:pixelCrop, :, :) = [];
currentData(:, end-pixelCrop:end, :, :) = [];

brainData = brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, scan),...
    'AxesColor', 'k',...
    'CLim', [-1 1],...
    'Color', 'w',...
    'ColorbarLabel', 'r',...
    'XTickLabel', (timesToPlot)*2,...
    'XLabel', 'Time (s)',...
    'YTickLabel', slicesToPlot,...
    'YLabel', 'Slice Number');

set(brainData.Axes.Primary, 'Color', 'k');
set(brainData.Axes.Primary, 'FontSize', 40);
set(get(brainData.Axes.Primary, 'XLabel'), 'FontSize', 50);
set(get(brainData.Axes.Primary, 'YLabel'), 'FontSize', 50);
set(get(brainData.Colorbar, 'YLabel'), 'FontSize', 50);
set(brainData.Colorbar, 'YTick', -1:1:1);

saveas(gcf, [fileStruct.Paths.Desktop '/SWC FPz-BOLD.png'], 'png');