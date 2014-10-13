%% 20140527 


%% 1141 - Sliding Window Correlation between BOLD-C3

cle

% Initialize some variables
channel = 'C3';             % <--- Robust correlations at multiple time shifts
sigOffset = 4;              % <--- Correlations strongest at ~4s
windowLength = 40;          % <--- 40 seconds captures one oscillation at 0.025 Hz
szBOLD = [91 109 91 218]; 
controlDelay = 4;
overlap = windowLength-2;

% Get the data set file paths
load masterStructs;
boldPath = [fileStruct.Paths.DataObjects '/BOLD/'];
boldStr = 'dcZ';
eegPath = [fileStruct.Paths.DataObjects '/EEG/'];
eegStr = 'dcZ';
boldFiles = get(fileData(boldPath, 'search', boldStr), 'Path');
eegFiles = get(fileData(eegPath, 'search', eegStr), 'Path');

% Convert time units to sample units
sigOffset = sigOffset * 0.5;
windowLength = windowLength * 0.5;
controlDelay = controlDelay * 0.5;
overlap = overlap * 0.5;

corrData = [];
progbar = progress('Sliding Window Correlation', 'Scans Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    
    reset(progbar, 2);
    for b = 1:length(boldData)
        
        % Get & mask the functional data
        functionalData = boldData(b).Data.Functional;
        functionalData = reshape(functionalData, [], szBOLD(4));
        idsMask = isnan(functionalData(:, 1));
        functionalData(idsMask, :) = [];
        
        % Extract control data
        motionSigs = boldData(b).Data.Nuisance.Motion';
        globalSig = boldData(b).Data.Nuisance.Global';
        wmSig = boldData(b).Data.Nuisance.WM';
        csfSig = boldData(b).Data.Nuisance.CSF';

        % Setup control data for each modality
        boldControl = [ones(size(functionalData, 2), 1), motionSigs, globalSig, wmSig, csfSig];
        globalSig = [zeros(controlDelay, 1); globalSig(1:end-controlDelay)];
        wmSig = [zeros(controlDelay, 1); wmSig(1:end-controlDelay)];
        eegControl = [ones(size(functionalData, 2), 1), motionSigs, globalSig, wmSig, csfSig];
        
        % Get the EEG data
        ephysData = eegData(b).Data.EEG(strcmpi(eegData(b).Channels, channel), :);
        
        % Regress control data
        functionalData = (functionalData' - boldControl*(boldControl\functionalData'))';
        ephysData = (ephysData' - eegControl*(boldControl\ephysData'))';
        
        % Apply a time shift for the hemodynamic delay
        ephysData(1:sigOffset) = [];
        functionalData(:, end-(sigOffset - 1):end) = [];
        
        % Crop out end time points that can't be used to construct a full
        % length window into the time series
        extraTimePoints = mod(length(ephysData), windowLength);
        if extraTimePoints ~= 0
            functionalData(:, end - (extraTimePoints - 1):end) = [];
            ephysData(end - (extraTimePoints - 1):end) = [];
        end
        
        % Calculate sliding window correlation
        tempCorr = zeros(size(functionalData, 1), (length(ephysData)-windowLength)/(windowLength - overlap));
        d = 1;
        for c = 1:(windowLength - overlap):length(ephysData)-windowLength
            tempCorr(:, d) = xcorrArr(functionalData(:, c:c+windowLength-1), ephysData(c:c+windowLength-1), 'MaxLag', 0);
            d = d + 1;
        end
        
        % Store the current correlation series
        currentCorr = nan(length(idsMask), size(tempCorr, 2));
        currentCorr(~idsMask, :) = tempCorr;
        currentCorr = reshape(currentCorr, [szBOLD(1:3) size(currentCorr, 2)]);
        corrData = cat(5, corrData, currentCorr);
        
        update(progbar, 2, b/length(boldData));
    end
    update(progbar, 1, a/length(boldFiles));
end
close(progbar);

% Create average correlation data & save everything
save([fileStruct.Paths.Desktop '/slidingWindowPartialCorr_' channel '_(' num2str(windowLength) ', ' num2str(overlap) ')_20140527.mat'], 'corrData', '-v7.3');


%% 1337 - Imaging the New Correlations
load slidingWindowPartialCorr_C3_(20, 19)_20140527.mat;
load masterStructs;

slicesToPlot = 48:4:64;
timesToPlot = 1:4:180;
titleStr = 'BOLD-C3 SWPC (Scan %i)';

for a = 1:size(corrData, 5)
    brainData = brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, a),...
        'Title', sprintf(titleStr, a),...
        'XTickLabel', (timesToPlot)*2,...
        'XLabel', 'Time (s)',...
        'YTickLabel', slicesToPlot,...
        'YLabel', 'Slice Number');    
    
    set(brainData.Axes.Primary, 'FontSize', 12);
    set(get(brainData.Axes.Primary, 'XLabel'), 'FontSize', 16);
    set(get(brainData.Axes.Primary, 'YLabel'), 'FontSize', 16);
    
    saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/' num2str(a) '.png'], 'png');
    close(brainData);
end


%% 1352 - Imaging Previously Generated BOLD-FPz SWCs
load slidingWindowPartialCorr_FPZ_(20, 19)_20140421.mat;
load masterStructs;

slicesToPlot = 48:4:64;
timesToPlot = 1:4:180;
titleStr = 'BOLD-FPz SWPC (Scan %i)';

for a = 1:size(corrData, 5)
    brainData = brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, a),...
        'Title', sprintf(titleStr, a),...
        'XTickLabel', (timesToPlot)*2,...
        'XLabel', 'Time (s)',...
        'YTickLabel', slicesToPlot,...
        'YLabel', 'Slice Number');    
    
    set(brainData.Axes.Primary, 'FontSize', 12);
    set(get(brainData.Axes.Primary, 'XLabel'), 'FontSize', 16);
    set(get(brainData.Axes.Primary, 'YLabel'), 'FontSize', 16);
    
    saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/' num2str(a) '.png'], 'png');
    close(brainData);
end


%% 1422 - Convert BOLD-FPz SWC Series into .IMG Files (in Preparation for Running ICA)
load slidingWindowPartialCorr_FPZ_(20, 19)_20140421.mat;
load masterStructs;

upperSavePath = [fileStruct.Paths.Desktop '/BOLD-FPz SWC IMG Files'];
if ~exist(upperSavePath, 'dir'); mkdir(upperSavePath); end;

for a = 1:size(corrData, 5)
    scanDir = [upperSavePath '/' num2str(a)];
    if ~exist(scanDir, 'dir'); mkdir(scanDir); end;
    
   for b = 1:size(corrData, 4)
       currentVolume = corrData(:, :, :, b, a);
       saveName = [scanDir '/' sprintf('%03d.img', b)];
       
       writeimg(saveName, currentVolume, 'double', [2, 2, 2], size(currentVolume));       
   end
end


%% 1437 - Convert BOLD-C3 SWC Series into .IMG Files (in Preparation for Running ICA)
load slidingWindowPartialCorr_C3_(20, 19)_20140527.mat;
load masterStructs;

upperSavePath = [fileStruct.Paths.Desktop '/BOLD-C3 SWC IMG Files'];
if ~exist(upperSavePath, 'dir'); mkdir(upperSavePath); end;

for a = 1:size(corrData, 5)
    scanDir = [upperSavePath '/' num2str(a)];
    if ~exist(scanDir, 'dir'); mkdir(scanDir); end;
    
   for b = 1:size(corrData, 4)
       currentVolume = corrData(:, :, :, b, a);
       saveName = [scanDir '/' sprintf('%03d.img', b)];
       
       writeimg(saveName, currentVolume, 'double', [2, 2, 2], size(currentVolume));       
   end
end


%% 1731 - SWC Between BOLD-PO8
cle

% Initialize some variables
channel = 'PO8';            % <--- Robust correlations at multiple time shifts
sigOffset = 4;              % <--- Correlations strongest at ~4s
windowLength = 40;          % <--- 40 seconds captures one oscillation at 0.025 Hz
szBOLD = [91 109 91 218]; 
controlDelay = 4;
overlap = windowLength-2;

% Get the data set file paths
load masterStructs;
boldPath = [fileStruct.Paths.DataObjects '/BOLD/'];
boldStr = 'dcZ';
eegPath = [fileStruct.Paths.DataObjects '/EEG/'];
eegStr = 'dcZ';
boldFiles = get(fileData(boldPath, 'search', boldStr), 'Path');
eegFiles = get(fileData(eegPath, 'search', eegStr), 'Path');

% Convert time units to sample units
sigOffset = sigOffset * 0.5;
windowLength = windowLength * 0.5;
controlDelay = controlDelay * 0.5;
overlap = overlap * 0.5;

corrData = [];
progbar = progress('Sliding Window Correlation', 'Scans Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    
    reset(progbar, 2);
    for b = 1:length(boldData)
        
        % Get & mask the functional data
        functionalData = boldData(b).Data.Functional;
        functionalData = reshape(functionalData, [], szBOLD(4));
        idsMask = isnan(functionalData(:, 1));
        functionalData(idsMask, :) = [];
        
        % Extract control data
        motionSigs = boldData(b).Data.Nuisance.Motion';
        globalSig = boldData(b).Data.Nuisance.Global';
        wmSig = boldData(b).Data.Nuisance.WM';
        csfSig = boldData(b).Data.Nuisance.CSF';

        % Setup control data for each modality
        boldControl = [ones(size(functionalData, 2), 1), motionSigs, globalSig, wmSig, csfSig];
        globalSig = [zeros(controlDelay, 1); globalSig(1:end-controlDelay)];
        wmSig = [zeros(controlDelay, 1); wmSig(1:end-controlDelay)];
        eegControl = [ones(size(functionalData, 2), 1), motionSigs, globalSig, wmSig, csfSig];
        
        % Get the EEG data
        ephysData = eegData(b).Data.EEG(strcmpi(eegData(b).Channels, channel), :);
        
        % Regress control data
        functionalData = (functionalData' - boldControl*(boldControl\functionalData'))';
        ephysData = (ephysData' - eegControl*(boldControl\ephysData'))';
        
        % Apply a time shift for the hemodynamic delay
        ephysData(1:sigOffset) = [];
        functionalData(:, end-(sigOffset - 1):end) = [];
        
        % Crop out end time points that can't be used to construct a full
        % length window into the time series
        extraTimePoints = mod(length(ephysData), windowLength);
        if extraTimePoints ~= 0
            functionalData(:, end - (extraTimePoints - 1):end) = [];
            ephysData(end - (extraTimePoints - 1):end) = [];
        end
        
        % Calculate sliding window correlation
        tempCorr = zeros(size(functionalData, 1), (length(ephysData)-windowLength)/(windowLength - overlap));
        d = 1;
        for c = 1:(windowLength - overlap):length(ephysData)-windowLength
            tempCorr(:, d) = xcorrArr(functionalData(:, c:c+windowLength-1), ephysData(c:c+windowLength-1), 'MaxLag', 0);
            d = d + 1;
        end
        
        % Store the current correlation series
        currentCorr = nan(length(idsMask), size(tempCorr, 2));
        currentCorr(~idsMask, :) = tempCorr;
        currentCorr = reshape(currentCorr, [szBOLD(1:3) size(currentCorr, 2)]);
        corrData = cat(5, corrData, currentCorr);
        
        update(progbar, 2, b/length(boldData));
    end
    update(progbar, 1, a/length(boldFiles));
end
close(progbar);

% Create average correlation data & save everything
save([fileStruct.Paths.Desktop '/slidingWindowPartialCorr_' channel '_(' num2str(windowLength) ', ' num2str(overlap) ')_20140527.mat'], 'corrData', '-v7.3');

% Image the correlations
slicesToPlot = 48:4:64;
timesToPlot = 1:4:180;
titleStr = 'BOLD-PO8 SWPC (Scan %i)';

for a = 1:size(corrData, 5)
    brainData = brainPlot('mri', corrData(:, :, slicesToPlot, timesToPlot, a),...
        'Title', sprintf(titleStr, a),...
        'XTickLabel', (timesToPlot)*2,...
        'XLabel', 'Time (s)',...
        'YTickLabel', slicesToPlot,...
        'YLabel', 'Slice Number');    
    
    set(brainData.Axes.Primary, 'FontSize', 12);
    set(get(brainData.Axes.Primary, 'XLabel'), 'FontSize', 16);
    set(get(brainData.Axes.Primary, 'YLabel'), 'FontSize', 16);
    
    saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/' num2str(a) '.png'], 'png');
    close(brainData);
end
