%% 20131104


%% 0727 - Resuming Work on Volume Conduction Analysis from Yesterday
% Reshape correlation matrix 
newCorrData = zeros(68, 68, 601, 17);
idx = 1:68:size(corrData, 2);
for a = 1:length(idx)
    newCorrData(:, :, :, a) = corrData(:, idx(a):idx(a)+67, :);
end

% Determine the indices of maximum cross correlation
[maxCorr, idxMax] = max(newCorrData, [], 3);


%% 0737 - Convert Indices of Maximum Correlation to Time Lags
timeLags = lags*1/eegData(1).Fs;
for a = 1:numel(idxMax)
    maxLags(a) = timeLags(idxMax(a));
end
maxLags = reshape(maxLags, size(idxMax));
maxLags = squeeze(maxLags);


%% 0741 - Plot the Data (2 Second Time Window)
channels = eegData(1).Channels;
for a = 1:17
    windowHandle(a) = windowObj('size', 'full');
    imagesc(maxLags(:, :, a), [-1 1])
    axis square
    windowHandle(a).Colorbar = colorbar;
    labelFigure(...
        'xLabels', channels,...
        'xRotation', 90,...
        'yLabels', channels);
    set(get(windowHandle(a).Colorbar, 'YLabel'), 'String', 'Time Lags (s)', 'FontSize', 14);
    saveas(windowHandle(a).FigureHandle, [num2str(a) '.png'], 'png');
end
close(windowHandle)


%% 0805 - Save Analysis Results
clear a b c ans eegData;
save([fileStruct.Paths.Desktop '/tempVolumeConductionAnalysis.mat']);


%% 1852 - Plotting Volume Conduction Data at Smaller Scales
load masterStructs
load([fileStruct.Paths.Desktop '/tempVolumeConductionAnalysis.mat']);

% 0.02 second time window
for a = 1:17
    windowHandle(a) = windowObj('size', 'full');
    imagesc(maxLags(:, :, a), [-0.01 0.01])
    axis square
    windowHandle(a).Colorbar = colorbar;
    labelFigure(...
        'xLabels', channels,...
        'xRotation', 90,...
        'yLabels', channels);
    set(get(windowHandle(a).Colorbar, 'YLabel'), 'String', 'Time Lags (s)', 'FontSize', 14);
    saveas(windowHandle(a).FigureHandle, [num2str(a) '.png'], 'png');
end
close(windowHandle)

% 0.2 second time window
for a = 1:17
    windowHandle(a) = windowObj('size', 'full');
    imagesc(maxLags(:, :, a), [-0.1 0.1])
    axis square
    windowHandle(a).Colorbar = colorbar;
    labelFigure(...
        'xLabels', channels,...
        'xRotation', 90,...
        'yLabels', channels);
    set(get(windowHandle(a).Colorbar, 'YLabel'), 'String', 'Time Lags (s)', 'FontSize', 14);
    saveas(windowHandle(a).FigureHandle, [num2str(a) '.png'], 'png');
end
close(windowHandle)