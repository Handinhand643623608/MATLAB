%% 20141117 


%% 1746 - Prototyping Empirical CDF Generation
% Log parameters
timeStamp = '201411171746';
analysisStamp = '';
dataSaveName = 'X:/Data/Today/20141117/201411171746 - ';

dof = 61.04;

nullTimeStamp = '201410031844';
nullPath = Path('E:\Graduate Studies\Lab Work\Data Sets\Today Data\20141003');
nullFiles = nullPath.FileSearch(nullTimeStamp);


corrTimeStamp = '201411061742';
corrFiles = Today.FindFiles(corrTimeStamp);

nullData = nullFiles(1).Load();
corrData = corrFiles(1).Load();

nullFPz = nullData.FPz;
corrFPz = corrData.FPz.Correlation;

nullFPz = atanh(nullFPz) .* sqrt(dof);

p = empiricalcdf(corrFPz, nullFPz);



%% 2227 - Running BOLD-EEG Coherence Again (Without Filtering & Nuisance Controls, Skipping Subjects 5-6)
% The last time coherence was run (201410031646), it was done between already-filtered data sets. I've always heard that
% coherence should not be estimated between filtered data (I don't currently know the specific reasons why) and it
% precludes a whole frequency range from analysis. In this case, frequencies between ~[0.1, 0.25] Hz were being lost.
% This section will redo that earlier analysis on unfiltered data.

% Log parameters
timeStamp = '201411172227';
analysisStamp = '%02d - BOLD-EEG MS Coherence';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
rsnMaskPath = [Paths.Common '/RSN Templates'];
rsnMaskFolders = rsnMaskPath.Contents;

rsnNames = {rsnMaskFolders.Name}';
rsnNames = strrep(rsnNames, ' ', '');

% Get references to infraslow BOLD & EEG data sets
boldPath = [Paths.BOLD '/Preprocessed'];
boldFiles = boldPath.FileContents();
eegPath = [Paths.EEG '/Unfiltered'];
eegFiles = eegPath.FileSearch('eegObject.*.mat');

% Remove subjects 5 & 6
boldFiles(9:13) = [];
eegFiles(9:13) = [];

cohData = emptystruct(rsnNames{:});
cohData = structfun(@(x) emptystruct(channels{:}), cohData, 'UniformOutput', false);

pb = Progress('-fast', 'BOLD-EEG MS Coherence', 'RSN Masks Processed', 'EEG Channels Processed');
for a = 1:length(boldFiles)
    
    boldFiles(a).Load();
    eegFiles(a).Load();
    LoadData(eegData);
    
    % These preprocessed data have misnamed anatomical segments that need correcting
    segData = boldData.Data.Segments;
    tempGM = segData.WM;
    segData.WM = segData.GM;
    segData.GM = tempGM;
    boldData.AsAdmin('boldData.Data.Segments = segData;');
    
    % Finish BOLD preprocessing (but skip temporal filtering)
    params = boldData.PrepParameters;
    boldData.AsAdmin('boldData.Preprocessing = params;');
    meanData = boldData.Data.Mean;
    minMean = min(meanData(:));
    meanData = (meanData - minMean) ./ (max(meanData(:)) - minMean);
    boldData.AsAdmin('boldData.Data.Mean = meanData;');
    boldData.AsAdmin('boldData.Data.Masks.Mean = (meanData > params.SegmentThresholds.MeanImageCutoff);');
    boldData.Blur(params.SpatialBlurring.Size, params.SpatialBlurring.Sigma, params.SpatialBlurring.ApplyToSegments);
    boldData.GenerateSegmentMasks();
    boldData.PrepRegressNuisance();
    boldData.ZScore();
    
    % Make a copy of the functional data to reuse
    origFunData = boldData.ToArray();
    
    % Store the unfiltered BOLD data for future use
    boldData.Store('Path', [Paths.BOLD.ToString() '/Unfiltered']);
    
    % Downsample the EEG data to match the BOLD
    ephysData = ToArray(eegData, channels);
    ephysData = ephysData(:, 1:600:end);
    ephysData = ephysData(1:boldData.NumTimePoints);
    
    pb.Reset(2);
    for b = 1:length(rsnNames)
        
        rsnMaskFile = rsnMaskFolders(b).FileSearch('.*.nii');
        rsnMask = load_nii(rsnMaskFile.ToString());
        rsnMask = logical(rsnMask.img);
        
        funData = maskImageSeries(origFunData, rsnMask, NaN);
        funData = reshape(funData, [], boldData.NumTimePoints);
        funData = nanmean(funData, 1);
        
        pb.Reset(3)
        for c = 1:length(channels)
            [currentCoh, freqs] = mscohere(funData, ephysData(c, :), [], [], [], 0.5);
            cohData.(rsnNames{b}).(channels{c}) = currentCoh;
            cohData.Frequencies = freqs;
            pbar.Update(3, c/length(channels));
        end
        pbar.Update(2, b/length(rsnMaskFolders));
    end
    
    Today.SaveData(timeStamp, sprintf(analysisStamp, a), cohData);
    
    pb.Update(1, a/length(boldFiles));
end
pb.close();

% NOTE FROM 201411201524:
% This section was never properly run. I needed to do some work on both the BOLD and EEG data objects to get them ready
% for this analysis. Work on coherence picks up again on in section 201411201508.