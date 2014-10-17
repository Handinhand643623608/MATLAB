%% 20131111


%% 1055 - Examining EEG Volume Conduction (for Downsampled DC Data)
% Get EEG data files
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'dcZ'), 'Path');
saveName = '20131111 - Volume Conduction Analysis Files (Downsampled DC)';

% Setup correlation parameters
maxLag = 218;

% Run correlation
corrData = [];
progBar = progress('Subjects Completed', 'Scans Completed');
for a = 1:length(eegFiles)
    load(eegFiles{a});
    standardize(eegData);
    reset(progBar, 2);
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            currentData = eegData(b).Data.EEG;
            for c = 1:size(currentData, 1);
                [currentCorr, lags] = xcorrArr(currentData, currentData(c, :), 'MaxLag', 218, 'ScaleOpt', 'coeff');
                szCorr = size(currentCorr);
                currentCorr = reshape(currentCorr, [szCorr(1), 1, szCorr(2)]);
                corrData = cat(2, corrData, currentCorr);
            end
        end
        update(progBar, 2, b/length(eegData));
    end
    update(progBar, 1, a/length(eegFiles));
end
close(progBar);

save([fileStruct.Paths.Desktop '/' saveName '.mat']);

% Reshape correlation matrix 
newCorrData = zeros(68, 68, 2*maxLag+1, 17);
idx = 1:68:size(corrData, 2);
for a = 1:length(idx)
    newCorrData(:, :, :, a) = corrData(:, idx(a):idx(a)+67, :);
end

% Determine the indices of maximum cross correlation
[maxCorr, idxMax] = max(newCorrData, [], 3);

timeLags = lags*1/eegData(1).Fs;
for a = 1:numel(idxMax)
    maxLags(a) = timeLags(idxMax(a));
end
maxLags = reshape(maxLags, size(idxMax));
maxLags = squeeze(maxLags);

% Plot the Data (2 Second Time Window)
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

clear a b c ans eegData;
save([fileStruct.Paths.Desktop '/' saveName '.mat']);


%% 1112 - Plotting Volume Conduction Data at Different Time Scales
% 436 second time window
for a = 1:17
    windowHandle(a) = windowObj('size', 'full');
    imagesc(maxLags(:, :, a), [-218 218])
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

% 6 second time window
for a = 1:17
    windowHandle(a) = windowObj('size', 'full');
    imagesc(maxLags(:, :, a), [-6 6])
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


%% 1118 - Examining EEG Volume Conduction (for Non-Downsampled DC Data)
% Get EEG data files
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'fbZ'), 'Path');
saveName = '20131111 - Volume Conduction Analysis Files (Non-Downsampled, DC)';

% Setup correlation parameters
maxLag = 300;       % <--- Track correlations over 1 s (300 samples/300 Hz) interval

% Run correlation
corrData = [];
progBar = progress('Subjects Completed', 'Scans Completed');
for a = 1:length(eegFiles)
    load(eegFiles{a});
    standardize(eegData);
    filter(eegData);    % <--- Filter to [0.01 0.08] Hz with a 45 s Hamming window
    reset(progBar, 2);
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            currentData = eegData(b).Data.EEG;
            for c = 1:size(currentData, 1);
                [currentCorr, lags] = xcorrArr(currentData, currentData(c, :), 'MaxLag', maxLag, 'ScaleOpt', 'coeff');
                szCorr = size(currentCorr);
                currentCorr = reshape(currentCorr, [szCorr(1), 1, szCorr(2)]);
                corrData = cat(2, corrData, currentCorr);
            end
        end
        update(progBar, 2, b/length(eegData));
    end
    update(progBar, 1, a/length(eegFiles));
end
close(progBar);

save([fileStruct.Paths.Desktop '/' saveName '.mat']);

% Reshape correlation matrix 
newCorrData = zeros(68, 68, 2*maxLag+1, 17);
idx = 1:68:size(corrData, 2);
for a = 1:length(idx)
    newCorrData(:, :, :, a) = corrData(:, idx(a):idx(a)+67, :);
end

% Determine the indices of maximum cross correlation
[maxCorr, idxMax] = max(newCorrData, [], 3);

timeLags = lags*1/eegData(1).Fs;
for a = 1:numel(idxMax)
    maxLags(a) = timeLags(idxMax(a));
end
maxLags = reshape(maxLags, size(idxMax));
maxLags = squeeze(maxLags);

% Save channel names & all current data
channels = eegData(1).Channels;
clear a b c ans eegData;
save([fileStruct.Paths.Desktop '/' saveName '.mat']);


%% 1323 - Examining EEG Volume Conduction (for Non-Downsampled DC, CSR Data)
% Get EEG data files
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'fbZ'), 'Path');
saveName = '20131111 - Volume Conduction Analysis Files (Non-Downsampled, DC, CSR)';

% Setup correlation parameters
maxLag = 300;       % <--- Track correlations over 1 s (300 samples/300 Hz) interval

% Run correlation
corrData = [];
progBar = progress('Subjects Completed', 'Scans Completed');
for a = 1:length(eegFiles)
    load(eegFiles{a});
    standardize(eegData);
    filter(eegData);                % <--- Filter to [0.01 0.08] Hz with a 45 s Hamming window
    regressCluster(eegData);        % <--- Regress cluster signals
    reset(progBar, 2);
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            currentData = eegData(b).Data.EEG;
            for c = 1:size(currentData, 1);
                [currentCorr, lags] = xcorrArr(currentData, currentData(c, :), 'MaxLag', maxLag, 'ScaleOpt', 'coeff');
                szCorr = size(currentCorr);
                currentCorr = reshape(currentCorr, [szCorr(1), 1, szCorr(2)]);
                corrData = cat(2, corrData, currentCorr);
            end
        end
        update(progBar, 2, b/length(eegData));
    end
    update(progBar, 1, a/length(eegFiles));
end
close(progBar);

save([fileStruct.Paths.Desktop '/' saveName '.mat']);

% Reshape correlation matrix 
newCorrData = zeros(68, 68, 2*maxLag+1, 17);
idx = 1:68:size(corrData, 2);
for a = 1:length(idx)
    newCorrData(:, :, :, a) = corrData(:, idx(a):idx(a)+67, :);
end

% Determine the indices of maximum cross correlation
[maxCorr, idxMax] = max(newCorrData, [], 3);

timeLags = lags*1/eegData(1).Fs;
for a = 1:numel(idxMax)
    maxLags(a) = timeLags(idxMax(a));
end
maxLags = reshape(maxLags, size(idxMax));
maxLags = squeeze(maxLags);

% Save channel names & all current data
channels = eegData(1).Channels;
clear a b c ans eegData;
save([fileStruct.Paths.Desktop '/' saveName '.mat']);


%% 1812 - Imaging Non-Downsampled DC Volume Conduction Data
load masterStructs
load([fileStruct.Paths.Desktop '/20131111 - Volume Conduction Analysis Files (Non-Downsampled, DC).mat']);

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

% 2 second time window
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


%% 1821 - Imaging Non-Downsampled, DC, CSR Volume Conduction Data
load masterStructs
load([fileStruct.Paths.Desktop '/20131111 - Volume Conduction Analysis Files (Non-Downsampled, DC, CSR).mat']);

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

% 2 second time window
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