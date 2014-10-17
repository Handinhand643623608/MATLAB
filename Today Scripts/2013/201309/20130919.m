%% 20130919

%% 1436
% Regenerate FB BOLD data from raw data (this time, include blurring & detrending)

% Get the raw data files
load masterStructs
searchStr = 'raw';
boldFiles = get(fileData(fileStruct.Paths.Raw, 'search', searchStr), 'Path');

% Setup the first subject
currentSubject = 1;
load(boldFiles{1});
tempGM = boldData.Data.Segments.WM;
boldData.Data.Segments.WM = boldData.Data.Segments.GM;
boldData.Data.Segments.GM = tempGM;
clear temp*

progBar = progress('Updating BOLD Data Objects');
for a = 2:length(boldFiles)
    % Load another BOLD data set
    currentBOLD = load(boldFiles{a});
    
    % Swap WM & GM segments
    tempGM = currentBOLD.boldData.Data.Segments.WM;
    currentBOLD.boldData.Data.Segments.WM = currentBOLD.boldData.Data.Segments.GM;
    currentBOLD.boldData.Data.Segments.GM = tempGM;
    clear temp*
    
    % If subject is the same as previously loaded, concatenate. Otherwise, condition & store.
    if currentBOLD.boldData.Subject == currentSubject
        boldData(currentBOLD.boldData.Scan) = currentBOLD.boldData;
    else
        % Condition the BOLD data
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
        
        % Store the BOLD data
        store(boldData);
        clear boldData
        
        % Setup another subject's BOLD data object
        boldData = currentBOLD.boldData;
        currentSubject = boldData.Subject;
    end
    update(progBar, a/length(boldFiles));
end
close(progBar)
    

%% 1552
% Regenerate DC BOLD data from raw data to fix errors during preprocessing
load masterStructs
searchStr = 'fbZ_20130919';
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', searchStr), 'Path');
oldBoldFiles = get(fileData(...
    'E:\Graduate Studies\Lab Work\Data Sets\Old Data (Not Used)\Data Objects\BOLD\GM & WM Segments Switched'),...
    'Path');

% Finish preprocessing of raw data (correct GM & WM segment switching)
progBar = progress('Processing BOLD Data');
for a = 6:length(boldFiles)
    
    % Load the raw data
    load(boldFiles{a})
    condParams = boldData(1).Preprocessing.Parameters.Conditioning;
    
    % Mask using the mean image
    mask(boldData, 'mean', condParams.MeanCutoff, NaN);
    
    % Identify nuisance parameters
    generateNuisance(boldData, 'Global');
    generateNuisance(boldData, 'WM');
    generateNuisance(boldData, 'CSF');
    
    % Filter the time series (BOLD + Nuisance)
    filter(boldData);
    
    % Grab motion parameters from old, unaffected data files (.1D files not available, & these are
    % already filtered)
    temp = load(oldBoldFiles{a}); 
    for b = 1:length(boldData)
        boldData(b).Data.Nuisance.Motion = temp.boldData(b).Data.Nuisance.Motion;
    end
    
    % Z-Score the data
    zscore(boldData);
    
    % Store the data set
    store(boldData);
    clear boldData temp;
    update(progBar, a/length(boldFiles));
end
close(progBar);
    

%% 1702
% Regenerate coherence data
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

cohStruct = parameters(cohObj);
cohStruct.Initialization.GSR = [false false];
cohStruct.Coherence.Masking.Threshold = 0.9;

for a = 1:length(channels)
    cohStruct.Coherence.Channels = channels(a);
    cohData = cohObj(cohStruct);
    store(cohData);
    meanCohData = mean(cohData);
    store(meanCohData);
    clear cohData meanCohData
end


%% 1905
% Plot & store coherence spectra
load masterStructs
cohFiles = get(fileData([fileStruct.Paths.DataObjects '/MS Coherence'], 'search', 'meanCohObject'), 'Path');

% Generate the plots
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
    
    saveas(gcf, [channel{1} '.png'], 'png');
    close
end
   

%% 1923
% Regenerate partial correlation results & store images
ccStruct = parameters(corrObj);
ccStruct.Initialization.GSR = [false false];
channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};

for a = 2:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    store(brainData, 'ext', {'png', 'pdf'});
    close(brainData);
    clear corrData meanCorrData
end

%% 2335
% Had to redo everything above several times in order to correct bugs & ensure things were being
% done properly