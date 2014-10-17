%% 20131001


%% 0956
% Re-running BOLD-EEG coherence, this time using partial coherence to regress BOLD nuisance control
% signals
cohStruct = parameters(cohObj);
cohStruct.Initialization.Relation = 'Partial Coherence';
cohStruct.Initialization.GSR = [false false];
cohStruct.Coherence.Masking.Threshold = 0.9;

channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};

for a = 1:length(channels)
    cohStruct.Coherence.Channels = channels(a);
    cohData = cohObj(cohStruct);
    store(cohData);
    meanCohData = mean(cohData);
    store(meanCohData);
end


%% 1010
% Can't rerun coherence until subject 8's FB BOLD data is generated (somehow, this didn't get saved
% previously')
load(boldFiles{1})
tempGM = boldData.Data.Segments.WM;
boldData.Data.Segments.WM = boldData.Data.Segments.GM;
boldData.Data.Segments.GM = tempGM;
currentBOLD = load(boldFiles{2});

% Swap WM & GM segments
tempGM = currentBOLD.boldData.Data.Segments.WM;
currentBOLD.boldData.Data.Segments.WM = currentBOLD.boldData.Data.Segments.GM;
currentBOLD.boldData.Data.Segments.GM = tempGM;
clear temp*

boldData(2) = currentBOLD.boldData;

condParams = boldData(1).Preprocessing.Parameters.Conditioning;
blur(boldData, condParams.SpatialBlurSize, condParams.SpatialBlurSigma);
detrend(boldData, condParams.DetrendOrder);  
zscore(boldData);

% Normalize & mask using the mean image
for b = 1:length(boldData)
    % Normalize the mean image
    meanData = boldData(b).Data.Mean;
    meanData = (meanData - min(meanData(:)))./(max(meanData(:)) - min(meanData(:)));
    boldData(b).Data.Mean = meanData;

    % Normalize the segments
    segmentStrs = fieldnames(boldData(b).Data.Segments);
    for c = 1:length(segmentStrs)
         currentSeg = boldData(b).Data.Segments.(segmentStrs{c});
         currentSeg = (currentSeg - min(currentSeg(:)))./(max(currentSeg(:)) - min(currentSeg(:))); 
         boldData(b).Data.Segments.(segmentStrs{c}) = currentSeg;
    end
end
mask(boldData, 'mean', condParams.MeanCutoff, NaN);
store(boldData);


%% 1207
% Had to rerun part of BOLD preprocessing on Brainiac in order to get unfiltered .1D motion
% parameter files. Now generate nuisance signals for FB BOLD data & store the objects afterward
load masterStructs
searchStr = 'fbZ_20130919';
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', searchStr), 'Path');
rawFolders =  get(fileData(fileStruct.Paths.Raw, 'folders', 'on', 'search', '10.A'), 'Path');

progBar = progress('Processing BOLD Data');
for a = 1:length(boldFiles)
    load(boldFiles{a})
    scanFolders = get(fileData(rawFolders{a}, 'folders', 'on', 'search', 'rest'), 'Path');
    
    for b = 1:length(boldData)
        motionFile = get(fileData(scanFolders{b}, 'ext', '.1D'), 'Path');
        motionParams = importdata(motionFile{1});
        boldData(b).Data.Nuisance.Motion = motionParams';
        boldData(b).Acquisition.MaxDeviation = max(max(motionParams, [], 1) - min(motionParams, [], 1));
    end
    
    generateNuisance(boldData, 'Global');
    generateNuisance(boldData, 'WM');
    generateNuisance(boldData, 'CSF');
    
    store(boldData)
end
    

%% 1253
% Now re-running the coherence analysis from above
cohStruct = parameters(cohObj);
cohStruct.Initialization.Relation = 'Partial Coherence';
cohStruct.Initialization.GSR = [false false];
cohStruct.Coherence.Masking.Threshold = 0.9;

channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};

for a = 1:length(channels)
    cohStruct.Coherence.Channels = channels(a);
    cohData = cohObj(cohStruct);
    store(cohData);
    meanCohData = mean(cohData);
    store(meanCohData);
end


%% 1436
% Plot the partial coherence spectra from above
load masterStructs
searchStr = 'meanPartialCohObj';
cohPath = [fileStruct.Paths.DataObjects '/Partial Coherence'];
cohFiles = get(fileData(cohPath, 'search', searchStr), 'Path');
imageSavePath = [fileStruct.Paths.Desktop '/Partial Coherence'];
if ~exist(imageSavePath, 'dir'); mkdir(imageSavePath); end;

for a = 1:length(cohFiles)
    load(cohFiles{a})
    channel = fieldnames(meanCohData.Data);
    
    shadePlot(...
        meanCohData.Parameters.Coherence.Frequencies,...
        meanCohData.Data.(channel{1}).Mean,...
        meanCohData.Data.(channel{1}).SEM,...
        '-k',...
        'Color', 'w');
    
    xlabel('Frequency (Hz)', 'FontSize', 14);
    ylabel('Magnitude Squared Coherence', 'FontSize', 14);
    title(['BOLD-' channel{1} ' Coherence'], 'FontSize', 16);
    
    saveas(gcf, [imageSavePath '/' channel{1} '.png'], 'png');
    saveas(gcf, [imageSavePath '/' channel{1} '.fig'], 'fig');
    close
end


%% 1502
% Threshold the coherence spectra for significance
load masterStructs
searchStr = 'meanPartialCohObj';
cohPath = [fileStruct.Paths.DataObjects '/Partial Coherence'];
cohFiles = get(fileData(cohPath, 'search', searchStr), 'Path');
imageSavePath = [fileStruct.Paths.Desktop '/Partial Coherence'];
if ~exist(imageSavePath, 'dir'); mkdir(imageSavePath); end;

% Setup thresholding parameters (these didn't exist in the parameters method before this script was written)
threshStruct = struct(...
    'AlphaVal', 0.05,...
    'CDFMethod', 'arbitrary',...
    'FWERMethod', 'sgof',...
    'Parallel', 'gpu',...
    'Tails', 'upper');
meanCohData.Parameters.Thresholding = threshStruct;
threshold(meanCohData, meanNullCohData);

progBar = progress('Thresholding Mean Partial Coherence Data');
for a = 2:length(cohFiles)
    load(cohFiles{a})
    meanCohData.Parameters.Thresholding = threshStruct;
    threshold(meanCohData)
    update(progBar, a/length(cohFiles));
end 


%% 1733
% Image the thresholded coherence spectra
load masterStructs
searchStr = 'meanPartialCohObj';
cohPath = [fileStruct.Paths.DataObjects '/Partial Coherence'];
cohFiles = get(fileData(cohPath, 'search', searchStr), 'Path');
imageSavePath = [fileStruct.Paths.Desktop '/Partial Coherence'];
if ~exist(imageSavePath, 'dir'); mkdir(imageSavePath); end;

for a = 1:length(cohFiles)
    load(cohFiles{a})
    
    channel = fieldnames(meanCohData.Data);
    freqs = meanCohData.Parameters.Coherence.Frequencies;
    
    shadePlot(...
        freqs,...
        meanCohData.Data.(channel{1}).Mean,...
        meanCohData.Data.(channel{1}).SEM,...
        '-k',...
        'Color', 'w');
    hold on
    plot(...
        freqs,...
        meanCohData.Parameters.SignificanceCutoffs.(channel{1})*ones(1, length(freqs)),...
        '--r');
        
    xlabel('Frequency (Hz)', 'FontSize', 14);
    ylabel('Magnitude Squared Coherence', 'FontSize', 14);
    title(['BOLD-' channel{1} ' Coherence'], 'FontSize', 16);
    
    saveas(gcf, [imageSavePath '/' channel{1} '.png'], 'png');
    saveas(gcf, [imageSavePath '/' channel{1} '.fig'], 'fig');
    close
end


%% 1739
% Generate FB CSR EEG data
load masterStructs
searchStr = 'fbZ';
eegPath = [fileStruct.Paths.DataObjects '/EEG'];
eegFiles = get(fileData(eegPath, 'search', searchStr), 'Path');

for a = 1:length(eegFiles)
    load(eegFiles{a})    
    regressCluster(eegData);
    zscore(eegData);
    store(eegData);
end


%% 1752
% Run coherence using CSR EEG data
cohStruct = parameters(cohObj);
cohStruct.Initialization.Relation = 'Partial Coherence';
cohStruct.Initialization.GSR = [false true];
cohStruct.Coherence.Masking.Threshold = 0.9;

channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};

progBar = progress('Generating Coherence Data');
for a = 1:length(channels)
    cohStruct.Coherence.Channels = channels(a);
    cohData = cohObj(cohStruct);
    store(cohData);
    meanCohData = mean(cohData);
    store(meanCohData);
    threshold(meanCohData);
    update(progBar, a/length(channels));
end
close(progBar)


%% 2149
% Image the thresholded coherence spectra
load masterStructs
searchStr = 'meanPartialCohObj';
cohPath = [fileStruct.Paths.DataObjects '/Partial Coherence'];
cohFiles = get(fileData(cohPath, 'search', searchStr), 'Path');
imageSavePath = [fileStruct.Paths.Desktop '/Partial Coherence'];
if ~exist(imageSavePath, 'dir'); mkdir(imageSavePath); end;

for a = 1:length(cohFiles)
    load(cohFiles{a})
    
    channel = fieldnames(meanCohData.Data);
    freqs = meanCohData.Parameters.Coherence.Frequencies;
    
    shadePlot(...
        freqs,...
        meanCohData.Data.(channel{1}).Mean,...
        meanCohData.Data.(channel{1}).SEM,...
        '-k',...
        'Color', 'w');
    hold on
    plot(...
        freqs,...
        meanCohData.Parameters.SignificanceCutoffs.(channel{1})*ones(1, length(freqs)),...
        '--r');
        
    xlabel('Frequency (Hz)', 'FontSize', 14);
    ylabel('Magnitude Squared Coherence', 'FontSize', 14);
    title(['BOLD-' channel{1} ' Coherence'], 'FontSize', 16);
    
    saveas(gcf, [imageSavePath '/' channel{1} '.png'], 'png');
    saveas(gcf, [imageSavePath '/' channel{1} '.fig'], 'fig');
    close
end