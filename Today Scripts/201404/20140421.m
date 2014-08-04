%% 20140421


%% 1516 - Trying Electrodes Opposite in Brain Hemisphere to Those Selected Before
% It occurred to me today, while looking at which electrodes were selected for correlation with BOLD
% signals, that the pattern of electrodes almost resembles the default mode network itself
% (excluding C3). Out of curiosity, I decided to investigate what correlation maps would look like
% if they instead used electrodes reflected about the brain's midline.

% Initialize correlation parameters
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'AF8', 'C4', 'PO7', 'PO9'};
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
    
progbar = progress('BOLD-EEG Partial Correlation (Reflected Electrodes)');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    clear corrData meanCorrData;
    update(progbar, a/length(channels));
end
close(progbar);


%% 1600 - Imaging the New Raw Correlation Maps

% Image the correlations
load masterStructs;
searchPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG/'];
searchStr = 'mean.*_20140421';
corrFiles = get(fileData(searchPath, 'Search', searchStr), 'Path');

for a = 1:length(corrFiles)
    load(corrFiles{a});
    brainData(a) = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData(a));
    clear meanCorrData;
end

% Results: these are quite interesting. AF8 correlates better with the RSNs than does any of the
% electrodes selected previously. It anticorrelates very well with DLPFC and ACC structures better
% than any other electrode tested to date. Anticorrelations with these structures between 0:6s are
% much stronger, and positive correlations with the ACC and DLPFC between 12:18s (where the sign
% inversion occurs) is far more robust. Not surprisingly, it shows the same evolution of correlation
% signs and spatial patterns with increasing time shifts as other frontal electrodes.
%
% C4 isn't as interesting as C3 and mostly shows the same thing, but weaker in intensity.
% Correlations in the SMA between 0-4s are stronger, but little else is remarkable.
%
% PO7 doesn't contain much that looks significant. The only noteworthy feature is an apparent
% positive correlation with DMN structures (MPFC, PCC, possibly LP) at approximately -14:-10s that
% doesn't appear at all in PO8. By the same token, essentially none of PO8's features appear in PO7
% either.
%
% PO9 contains virtually nothing significant-looking.
%
% It's tough to say what's going on here. Could be any number of things, really. Could be that these
% electrodes are different electro-mechanically than those on the opposite hemisphere (e.g. maybe
% they consistently don't make good contact with the scalp). It could also be that these should be
% much more similar to their reflected electrodes, but individual variations still rule the outcome
% because of our small sample size.
%
% However, it's tempting to think that, given the differences outlined above, this could be evidence
% that of different electrodes driving different parts of the RSNs at different times. The networks
% can and do appear somewhat fragmented in the correlation images, somewhat unlike the stationary FC 
% images that people have come to know. 


%% 1613 - Running Another Series using Temporal Electrodes & Cz
% I wonder what these electrodes are up to while all of this is going on...

% Initialize correlation parameters
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'CZ', 'T7', 'T8'};
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
    
progbar = progress('BOLD-EEG Partial Correlation (Reflected Electrodes)');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    clear corrData meanCorrData;
    update(progbar, a/length(channels));
end
close(progbar);


%% 1644 - Imaging the New Raw Correlation Maps

% Image the correlations
load masterStructs;
searchPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG/'];
searchStr = 'mean.*_20140421';
corrFiles = get(fileData(searchPath, 'Search', searchStr), 'Path');

for a = 1:length(corrFiles)
    load(corrFiles{a});
    brainData(a) = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData(a));
    clear meanCorrData;
end

close(brainData)

% Results: there's a lot going on here. Going to have to find a way to summarize all of the data.
% Eventually, I plan to run correlations between BOLD and all electrodes, so this would be good to
% do anyway.


%% 1655 - Running Another Series using POz
% The most posterior midline electrode common to all subjects

% Initialize correlation parameters
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'POZ'};
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
    
progbar = progress('BOLD-EEG Partial Correlation (Reflected Electrodes)');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    clear corrData meanCorrData;
    update(progbar, a/length(channels));
end
close(progbar);


%% 1706 - Imaging the New Raw Correlation Maps

% Image the correlations
load masterStructs;
searchPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG/'];
searchStr = 'mean.*POZ.*_20140421';
corrFiles = get(fileData(searchPath, 'Search', searchStr), 'Path');

for a = 1:length(corrFiles)
    load(corrFiles{a});
    brainData(a) = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData(a));
    clear meanCorrData;
end

close(brainData)


%% 1806 - Finally Trying Sliding Window Correlation between BOLD-EEG

cle

% Initialize some variables
channel = 'FPZ';            % <--- Robust correlations at multiple time shifts
sigOffset = 4;              % <--- Correlations strongest at ~4s
windowLength = 20;          % <--- 20 seconds captures one oscillation at 0.05 Hz, where BOLD-EEG coherence was strongest for this electrode.
szBOLD = [91 109 91 218];

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
        
        % Get the EEG data & apply a time shift for the hemodynamic delay
        ephysData = eegData(b).Data.EEG(strcmpi(eegData(b).Channels, channel), :);
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
        tempCorr = zeros(size(functionalData, 1), length(ephysData)/windowLength);
        d = 1;
        for c = 1:windowLength:length(ephysData)
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
save([fileStruct.Paths.Desktop '/slidingWindowCorr_FPZ_(' num2str(windowLength) ', 0)_20140421.mat'], 'corrData', '-v7.3');
meanCorrData = nanmean(corrData, 5);
save([fileStruct.Paths.Desktop '/meanSlidingWindowCorr_FPZ_(' num2str(windowLength) ', 0)20140421.mat'], 'corrData', '-v7.3');


%% 1830 - Crudely Imaging SWC Data

% brainData = brainPlot('mri', meanCorrData(:, :, 48:4:64, :), 'CLim', [-0.5, 0.5]);

brainData = brainPlot('mri', corrData(:, :, 48:4:64, :, 7), 'CLim', [-1, 1])


%% 1849 - Re-Trying SWC, Using Partial Correlation to Control for BOLD Nuisance
% Also, I realized only after running the previous two sections that taking the average of the
% correlations across subjects no longer makes sense (electrodes might desynchronize with BOLD at
% any time). So, I removed this part.

cle

% Initialize some variables
channel = 'FPZ';            % <--- Robust correlations at multiple time shifts
sigOffset = 4;              % <--- Correlations strongest at ~4s
windowLength = 20;          % <--- 20 seconds captures one oscillation at 0.05 Hz, where BOLD-EEG coherence was strongest for this electrode.
szBOLD = [91 109 91 218];
controlDelay = 4;

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
        tempCorr = zeros(size(functionalData, 1), length(ephysData)/windowLength);
        d = 1;
        for c = 1:windowLength:length(ephysData)
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
save([fileStruct.Paths.Desktop '/slidingWindowPartialCorr_FPZ_20140421.mat'], 'corrData', '-v7.3');


%% 1928 - Imaging All SWC Data
for a = 1:size(corrData, 5)
    brainData(a) = brainPlot('mri', corrData(:, :, 48:4:64, :, a), 'CLim', [-1, 1]);
end


%% 1941 - Re-Trying SWC, Using a Wider Window Length

cle

% Initialize some variables
channel = 'FPZ';            % <--- Robust correlations at multiple time shifts
sigOffset = 4;              % <--- Correlations strongest at ~4s
windowLength = 40;          % <--- 20 seconds captures one oscillation at 0.05 Hz, where BOLD-EEG coherence was strongest for this electrode.
szBOLD = [91 109 91 218];
controlDelay = 4;
overlap = 0;

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
        tempCorr = zeros(size(functionalData, 1), length(ephysData)/windowLength);
        d = 1;
        for c = 1:windowLength:length(ephysData)
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
save([fileStruct.Paths.Desktop '/slidingWindowPartialCorr_FPZ_(' num2str(windowLength) ', ' num2str(overlap) ')_20140421.mat'], 'corrData', '-v7.3');


%% 1950 - Imaging SWC Above
for a = 1:size(corrData, 5)
    brainData(a) = brainPlot('mri', corrData(:, :, 48:4:64, :, a), 'CLim', [-1, 1]);
end


%% 1956 - Now doing SWC Using Overlapping Windows
cle

% Initialize some variables
channel = 'FPZ';            % <--- Robust correlations at multiple time shifts
sigOffset = 4;              % <--- Correlations strongest at ~4s
windowLength = 40;          % <--- 20 seconds captures one oscillation at 0.05 Hz, where BOLD-EEG coherence was strongest for this electrode.
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
save([fileStruct.Paths.Desktop '/slidingWindowPartialCorr_FPZ_(' num2str(windowLength) ', ' num2str(overlap) ')_20140421.mat'], 'corrData', '-v7.3');


%% 2013 - Imaging SWC Above & Creating a Movie from the Data
% for a = 1:size(corrData, 5)
%     brainData(a) = brainPlot('mri', corrData(:, :, 48:4:64, :, a), 'CLim', [-1, 1]);
% end
slicesToPlot = 48:4:64;
brainData = brainPlot('mri', corrData(:, :, 48:4:64, 1:4:end, 1), 'CLim', [-1, 1]);
cmap = get(brainData, 'Colormap');

temp = corrData(:, :, slicesToPlot, :, 1);
temp = flipdim(permute(temp, [2 1 3 4]), 1);
temp = reshape(squeeze(temp), [], 91, 1, size(corrData, 4));
temp(isnan(temp)) = 0;
minVal = min(temp(:));
maxVal = max(temp(:));
temp = ((length(cmap)- 1)*(temp - minVal)/(maxVal - minVal)) + 1;

brainMovie = immovie(temp, cmap);
implay(brainMovie);

