%% 20131126


%% 0015 - Testing out BOLD-RSN Correlations (DMN in Subject 1)
load boldObject-1_RS_dcZ_20131030;

for a = 1:length(boldData)
    functionalData = boldData(a).Data.Functional;
    szBOLD = size(functionalData);
    functionalData = reshape(functionalData, [], szBOLD(4));
    icData = boldData(a).Data.ICA.DMN;
    corrData(:, :, a) = xcorrArr(functionalData, icData, 'ScaleOpt', 'coeff'); 
end

for a = 1:2
    shapedData(:, :, :, :, a) = reshape(corrData(:, :, a), [szBOLD(1:3), size(corrData, 2)]);
end

slicesToPlot = 48:4:64;
shiftsToPlot = 1:22:435;

for a = 1:2
    brainData(a) = brainPlot('mri', shapedData(:, :, slicesToPlot, shiftsToPlot, a));
end


%% 0032 - Looking at PSD Estimates of RSN Time Series (DMN in Subject 1)
for a = 1:length(boldData)
    icData = boldData(a).Data.ICA.DMN;
    [psdData(:, a), freqs] = pwelch(icData, [], [], [], 0.5);
    
    figure;
    plot(freqs, psdData(:, a))
end


%% 0045 - Looking at PSD Estimates of RSN Time Series (DAN in Subject 1)
for a = 1:length(boldData)
    icData = boldData(a).Data.ICA.DAN;
    [psdData(:, a), freqs] = pwelch(icData, [], [], [], 0.5);
    
    figure;
    plot(freqs, psdData(:, a))
end


%% 0101 - Generating Average PSDs Across Subjects of RSN Time Series (DMN & DAN)
% Get BOLD data files
load masterStructs
boldFiles = get(fileData([fileStruct.Paths.DataObjects '\BOLD'], 'Search', 'dcZ'), 'Path');

allDMN = [];
allDAN = [];

progbar = progress('Subjects Completed', 'Scans Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    
    reset(progbar, 2)
    for b = 1:2
        if ~isempty(boldData(b).Data)
            % Gather ICA data
            dmnData = boldData(b).Data.ICA.DMN;
            danData = boldData(b).Data.ICA.DAN;
            
            % Welch PSD estimates
            [dmnPSD, freqs] = pwelch(dmnData, [], [], [], 0.5);
            [danPSD, freqs] = pwelch(danData, [], [], [], 0.5);
            
            % Concatenate results
            allDMN = cat(2, allDMN, dmnPSD);
            allDAN = cat(2, allDAN, danPSD);
            
        end
        update(progbar, 2, b/length(boldData));
    end
    update(progbar, 1, a/length(boldFiles));
end
close(progbar)

% Average PSDs together
meanDMN = mean(allDMN, 2);
meanDAN = mean(allDAN, 2);

% Plot group averages
figure;
plot(freqs, 10*log10(meanDMN));
figure;
plot(freqs, 10*log10(meanDAN));

% DMN: Peak power at ~0.017 Hz (consistent with literature)
% DAN: Peak power at ~0.023 Hz


%% 0148 - Running BOLD-RSN Cross-Correlations for All Subjects
% Setup correlation parameters
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false false],...
        'Modalities', 'BOLD-RSN',...
        'Relation', 'Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', [],...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', {{[1 2] [1 2] [1 2] [1 2] [1 2] [1 2] [1 2] [1 2]}},...      % <--- No ICA time courses for subject 6 scan 3
        'Subjects', [1:8],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', [],...
        'MaskThreshold', [],...
        'Parallel', 'gpu',...
        'Tails', 'both'));
corrData = corrObj(ccStruct);
store(corrData)
meanCorrData = mean(corrData);
store(meanCorrData)                 % <--- Errored out here (bug in correlation code prevented unmasking of data)

brainData = plot(meanCorrData, 'CLim', [-3 3]);
store(brainData, 'ext', {'fig', 'png'});
close(brainData)


%% 1117 - Fixing Error in BOLD-RSN Correlations (Gathering Masks Indices to Unmask Data)
load masterStructs
boldFiles = get(fileData([fileStruct.Paths.DataObjects '\BOLD'], 'Search', 'dcZ'), 'Path');

idsMask = cell(8, 2);

progbar = progress('Gathering Mask Ids');
for a = 1:length(boldFiles)
    load(boldFiles{a})
    
    for b = 1:2
        funData = boldData(b).Data.Functional;
        funData = reshape(funData, [], size(funData, 4));
        idsMask{a, b} = isnan(funData(:, 1));
    end
    
    clear boldData
    update(progbar, a/length(boldFiles));
end
close(progBar)


%% 1129 - Unmasking Correlation Values so They Can be Averaged Together
icNames = corrData(1, 1).Parameters.Correlation.DataStrs;
for a = 1:size(corrData, 1)
    for b = 1:size(corrData, 2)
        for c = 1:length(icNames)
            % Restore trimmed data
            currentCorr = corrData(a, b).Data.(icNames{c});
            tempCorr = nan([length(idsMask{a, b}) size(currentCorr, 2)]);
            tempCorr(~idsMask{a, b}, :) = currentCorr;
            
            % Reshape data to volumetric array
            corrData(a, b).Data.(icNames{c}) = reshape(tempCorr, [91, 109, 91, size(currentCorr, 2)]);
        end
    end
end


%% 1147 - Resuming Analysis (Generate & Plot Mean BOLD-RSN Correlation Data, Unthresholded)
% Generate mean correlation data
clearvars -except corrData
store(corrData)
meanCorrData = mean(corrData);
store(meanCorrData);
clear corrData

% Plot correlation data
brainData = plot(meanCorrData, 'CLim', [-3 3]);
store(brainData, 'ext', {'fig', 'png'});


%% 1240 - Try General Thresholding of Images @ Z=2
icNames = meanCorrData.Parameters.Correlation.DataStrs;

for a = 1:length(icNames)
    meanCorrData.Parameters.SignificanceCutoffs.(icNames{a}) = [-2 2];
end

brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
store(brainData, 'ext', {'fig', 'png'});


%% 1314 - Re-Plot Data Using the Newly Implemented Colin Brain
icNames = meanCorrData.Parameters.Correlation.DataStrs;

for a = 1:length(icNames)
    meanCorrData.Parameters.SignificanceCutoffs.(icNames{a}) = [-2 2];
end

brainData = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
store(brainData, 'ext', {'fig', 'png'});

% Nothing too surprising in these results. Most correlation maps look roughly like they're supposed to. Lots of extra
% correlations in surrounding structures for several of them, but since independence is no longer enforced, it's pretty
% much expected. 


%% 1443 - Examining Average PSDs of All RSNs
load masterStructs
boldFiles = get(fileData([fileStruct.Paths.DataObjects '\BOLD'], 'Search', 'dcZ'), 'Path');

% Calculate PSDs for all RSNs
allData = struct('Data', [], 'Mean', [], 'SEM', []);
progbar = progress('Calculating RSN PSDs', 'Scans Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a})
    reset(progbar, 2);
    for b = 1:2
        icNames = fieldnames(boldData(b).Data.ICA);
        for c = 1:length(icNames)
            currentData = boldData(b).Data.ICA.(icNames{c});
            [currentPSD, freqs] = pwelch(currentData, [], [], [], 0.5);
            if ~isfield(allData.Data, icNames{c})
                allData.Data.(icNames{c}) = [];
            end
            allData.Data.(icNames{c}) = cat(2, allData.Data.(icNames{c}), currentPSD);
        end
        update(progbar, 2, b/2);
    end
    update(progbar, 1, a/length(boldFiles));
end
close(progbar);

% Calculate mean & SEM of PSD data
for a = 1:length(icNames)
    allData.Mean.(icNames{a}) = mean(allData.Data.(icNames{a}), 2);
    allData.SEM.(icNames{a}) = std(allData.Data.(icNames{a}), [], 2)./sqrt(size(allData.Data.(icNames{a}), 2));
end


%% 1519 - Image the Average PSDs
for a = 1:length(icNames)
    currentMean = log10(allData.Mean.(icNames{a}));
    currentSEM = log10(allData.SEM.(icNames{a}));
    h(a) = shadePlot(freqs, currentMean, currentSEM, '-k',...
        'Title', ['Average PSD for ' icNames{a} ' RSN'],...
        'XLabel', 'Frequency (Hz)',...
        'YLabel', 'Power (dB/Hz)');
end

load masterStructs
savePath = [fileStruct.Paths.Desktop '\RSN PSDs'];
mkdir(savePath);
for a = 1:length(h)
    saveas(h(a).FigureHandle, [savePath '\' icNames{a} '.fig']);
    saveas(h(a).FigureHandle, [savePath '\' icNames{a} '.png']);
end
close(h)

% These average spectra aren't very telling. Over the infraslow (<0.1 Hz) range power is positive, but fairly flat for
% each RSN. Sometimes a small distinct peak is observable. 


%% 1706 - Re-Running BOLD-EEG Partial Cross-Correlations (Delayed Control Signals, no BOLD Global Signal, no EEG CSR)
% Shella pointed out that it would be logical to delay certain control signals when regressing them from EEG data. I
% implemented this in the partialCorrelation method of corrObj as a 4 second delay in the Global, WM, & CSF signals. Now
% need to try it out to see if it makes a difference. Also, for this first trial, I'm eliminating the BOLD global
% control signal (literature suggests controlling for this is a bad idea).
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false false],...
        'Modalities', 'BOLD-EEG',...
        'Relation', 'Partial Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', {{'Motion', 'WM', 'CSF'}},...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', [],...
        'Subjects', [],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', gmMask,...
        'MaskThreshold', 0.7,...
        'Parallel', 'gpu',...
        'Tails', 'both'));

progBar = progress('Partial Correlation Channels Completed');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'fig', 'png'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);

% Results: these look a little messy (see C3, PO8, PO10 electrodes). AF7 & FPz look alright. More detailed analysis to
% follow when more results are gathered.


%% 1834 - Re-Running BOLD-EEG Partial Correlations (Delayed Control Signals, no BOLD Global Signal, EEG CSR)
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false true],...
        'Modalities', 'BOLD-EEG',...
        'Relation', 'Partial Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', {{'Motion', 'WM', 'CSF'}},...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', [],...
        'Subjects', [],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', gmMask,...
        'MaskThreshold', 0.7,...
        'Parallel', 'gpu',...
        'Tails', 'both'));

progBar = progress('Partial Correlation Channels Completed');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'fig', 'png'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);

% Results: still messy. But networks are definitely more visible in a several electrodes. 


%% 1942 - Re-Running BOLD-EEG Partial Correlations (Delayed Control Signals, Including BOLD Global signal, no EEG CSR)
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false false],...
        'Modalities', 'BOLD-EEG',...
        'Relation', 'Partial Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', {{'Motion', 'Global', 'WM', 'CSF'}},...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', [],...
        'Subjects', [],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', gmMask,...
        'MaskThreshold', 0.7,...
        'Parallel', 'gpu',...
        'Tails', 'both'));

progBar = progress('Partial Correlation Channels Completed');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'fig', 'png'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);

% Results: these look good (at least not full of noise), but they're virtually identical (some minute variation, but
% nothing major at all) to the old results when nuisance signals weren't being delayed. These results suggest that the
% time delay on nuisance signals has an essentially negligible effect.


%% 2103 - Re-Running BOLD-EEG Partial Correlations (Delayed Control Signals, Including BOLD Global signal, EEG CSR)
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false true],...
        'Modalities', 'BOLD-EEG',...
        'Relation', 'Partial Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', {{'Motion', 'Global', 'WM', 'CSF'}},...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', [],...
        'Subjects', [],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', gmMask,...
        'MaskThreshold', 0.7,...
        'Parallel', 'gpu',...
        'Tails', 'both'));

progBar = progress('Partial Correlation Channels Completed');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'fig', 'png'});
    close(brainData)
    clear corrData meanCorrData;
    update(progBar, a/length(channels));
end
close(progBar);

% Results: same conclusion as in the last section. Very few visible differences between these results & previous ones
% where control signals weren't being delayed. 