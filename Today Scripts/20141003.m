%% 20141003 


%% 1646 - Running BOLD-EEG Coherence without Nuisance Controls & Skipping Subjects 5 & 6
% Today's parameters
timeStamp = '201410031646';
analysisStamp = 'BOLD-EEG MS Coherence';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141003/201410031646 - %d ';

% Updates to human data objects have started generating loading error (but none critical yet)
warning('off', 'MATLAB:class:noSetMethod');

% Coherence parameters
channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
rsnMaskPath = Search(Paths, 'Globals', 'RSN Templates', 'Ext', 'folder');
rsnMaskFolders = searchdir(rsnMaskPath{1}, [], 'Ext', 'folder');
rsnMaskFolders(1:2) = [];

% Get the BOLD & EEG data files
boldFiles = get(Paths, 'InfraslowBOLD');
eegFiles = get(Paths, 'InfraslowEEG');

% Remove subjects 5 & 6
boldFiles(9:13) = [];
eegFiles(9:13) = [];

cohData = struct;

pbar = Progress('-fast', 'BOLD-EEG MS Coherence', 'RSN Masks Processed', 'EEG Channels Processed');
for a = 1:length(boldFiles)

    load(boldFiles{a});
    load(eegFiles{a});
    
    % Regress nuisance parameters from BOLD only (not including the global signal)
    [nuisanceData, legend] = boldData.ToArray('nuisance');
    nuisanceData(strcmpi(legend, 'Global'), :) = [];
    boldData.Regress(nuisanceData);
    
    % Make a copy of the functional data to reuse
    origFunData = boldData.ToArray();
    
    pbar.Reset(2);
    for b = 1:length(rsnMaskFolders)
        
        % Get the RSN mask IMG
        rsnMaskFile = searchdir(rsnMaskFolders{b}, [], 'Ext', '.nii');
        rsnMask = load_nii(rsnMaskFile{1});
        rsnMask = logical(rsnMask.img);
        
        % Generate an RSN name from the file
        [~, rsnName, ~] = fileparts(rsnMaskFile{1});
        rsnName = strrep(rsnName, ' ', '');
        
        % Mask the BOLD time series using the RSN data
        funData = maskImageSeries(origFunData, rsnMask, NaN);
        funData = reshape(funData, [], boldData.NumTimePoints);
        funData = nanmean(funData, 1);
        
        % Run coherence between each EEG channel & the average RSN time series
        pbar.Reset(3)
        for c = 1:length(channels)
            ephysData = eegData(channels{c});
            [currentCoh, freqs] = mscohere(funData, ephysData, [], [], [], 0.5);
            cohData.(rsnName).(channels{c}) = currentCoh;
            cohData.Frequencies = freqs; 
            pbar.Update(3, c/length(channels));
        end
        pbar.Update(2, b/length(rsnMaskFolders));
    end
    
    % Save the coherence data per scan
    save(sprintf([dataSaveName analysisStamp], a), 'cohData');
    
    pbar.Update(1, a/length(boldFiles));
end
pbar.close();



%% 1752 - Running BOLD-EEG Correlations without Nuisance Controls & Skipping Subjects 5 & 6
% Today's parameters
timeStamp = '201410031752';
analysisStamp = 'BOLD-EEG Correlation';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141003/201410031752 - %d ';

% Updates to human data objects have started generating loading error (but none critical yet)
warning('off', 'MATLAB:class:noSetMethod');

% Correlation parameters
channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
maxLag = 20;

% Get the BOLD & EEG data files
boldFiles = get(Paths, 'InfraslowBOLD');
eegFiles = get(Paths, 'InfraslowEEG');

% Remove subjects 5 & 6
boldFiles(9:13) = [];
eegFiles(9:13) = [];

corrData = struct;

pbar = Progress('BOLD-EEG Cross Correlation', 'EEG Channels Processed');
for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    load(eegFiles{a});
    
    % Regress nuisance parameters from BOLD only (not including the global signal)
    [nuisanceData, legend] = boldData.ToArray('nuisance');
    nuisanceData(strcmpi(legend, 'Global'), :) = [];
    boldData.Regress(nuisanceData);
    
    [funData, idsNaN] = boldData.ToMatrix();
    corrVol = nan(length(idsNaN), 2*maxLag + 1);
    
    pbar.Reset(2);
    for b = 1:length(channels)
        
        ephysData = eegData(channels{b});
        [corrVol(~idsNaN, :), lags] = xcorrArr(funData, ephysData, 'MaxLag', maxLag);
        corrData.(channels{b}) = reshape(corrVol, [91, 109, 91, length(lags)]);
        corrData.Lags = lags * 2;
        pbar.Update(2, b/length(channels));
        
    end
    
    save(sprintf([dataSaveName analysisStamp], a), 'corrData');
    
    pbar.Update(1, a/length(boldFiles));
end
pbar.close();   
    


%% 1844 - Generating a Null Distribution for the Correlations Above
% Today's parameters
timeStamp = '201410031844';
analysisStamp = 'BOLD-EEG Null Correlation';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141003/201410031844 - %d ';

% Updates to human data objects have started generating loading error (but none critical yet)
warning('off', 'MATLAB:class:noSetMethod');

% Correlation parameters
channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
maxLag = 20;

% Get the BOLD & EEG data files
boldFiles = get(Paths, 'InfraslowBOLD');
eegFiles = get(Paths, 'InfraslowEEG');

% Remove subjects 5 & 6
boldFiles(9:13) = [];
eegFiles(9:13) = [];

pairings = nchoosek(1:length(boldFiles), 2);
boldFileNum = 0;

corrData = struct;

pbar = Progress('BOLD-EEG Null Correlation', 'EEG Channels Processed');
for a = 1:size(pairings, 1)
    
    if (pairings(a, 1) ~= boldFileNum)
        
        boldFileNum = pairings(a, 1);
        load(boldFiles{boldFileNum});
        
        % Regress nuisance parameters from BOLD only (not including the global signal)
        [nuisanceData, legend] = boldData.ToArray('nuisance');
        nuisanceData(strcmpi(legend, 'Global'), :) = [];
        boldData.Regress(nuisanceData);
        
        [funData, idsNaN] = boldData.ToMatrix();
        
    end
    
    load(eegFiles{pairings(a, 2)});
    corrVol = nan(length(idsNaN), 2*maxLag + 1);
    
    pbar.Reset(2);
    for b = 1:length(channels)
        
        ephysData = eegData(channels{b});
        [corrVol(~idsNaN, :), lags] = xcorrArr(funData, ephysData, 'MaxLag', maxLag);
        corrData.(channels{b}) = reshape(corrVol, [91, 109, 91, length(lags)]);
        corrData.Lags = lags .* 2;
        pbar.Update(2, b/length(channels));
    
    end
    
    save(sprintf([dataSaveName analysisStamp], a), 'corrData');
    
    pbar.Update(1, a/size(pairings, 1));
end
pbar.close();
