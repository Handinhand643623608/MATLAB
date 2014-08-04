%% SWC between DMN & TPN in BOLD Signals

%% CHANGELOG
%   Written by Josh Grooms on 20140729

%% DEPENDENCIES
%   SPM
%   - AAL toolbox
%   - MarsBar ROI toolbox
%
%   @boldObj
%
%   where
%   xcorrArr   

%% NOTES ON ANALYSIS
%   - Garth & (Chang 2010) both reverse normalized the AAL labeled brain to individual space
%       > This is being ignored for now because we have whole-brain coverage & not doing so is a lot easier
%       > Might need to implement this if results don't agree with Garth's
%   - Garth arrived at the 10% of voxels per network estimate heuristically
%       > We may need to adjust this value somewhat
%   - Garth performed GSR
%       > We aren't doing this; GSR was considered less of a bad idea back when he did it
%       > Also, we have whole-brain data, whereas he only had a few slices
%   - Nuisance regressions



%% Initialize Analysis Parameters

% Network identification parameters
idxROI = 6301;                      % The index of the seed ROI (left precuneus is 6301)
pctVoxelsPerNetwork = 0.1;          % The percentage of all voxels included in average RSN signal calculation (0.1 = 10%)
averageNetworkIdsThreshold = 0.5;   % The RSN mask threshold in the range [0, 1]

% Sliding window correlation (SWC) parameters
windowLength = 17;                  % Window length in samples (17 TRs = 11.9s < (1/0.08) Hz)
windowOverlap = windowLength - 1;   % The overlap between successive windows in samples

% Data selection parameters
pathToData = '/home/cgodwin9/DMC2/preprocessed';
boldFileStr = 'boldObject.*\d{8}';

% SPM dependency paths
aalPath = [where('spm') '/toolbox/AAL'];

% Find the BOLD data files
boldFiles = get(fileData(pathToData, 'Search', boldFileStr, 'Ext', '.mat'), 'Path');



%% Generate Some Formatted Data for the Analysis

subjectsToRun = [];
for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    
    % Keep track of which subject numbers are being used
    if ~ismember(boldData.Subject, subjectsToRun)
        subjectsToRun = cat(2, subjectsToRun, boldData.Subject);
    end
    
    % Load any MATFILE data
    if isa(boldData.Data, 'matlab.io.MatFile')
        boldData.Data = load(boldData.Data.Properties.Source);
    end

    % Generate & regress all available nuisance parameters
    GenerateNuisance(boldData);
    nuisanceData = ToArray(boldData, 'nuisance');
    Regress(boldData, nuisanceData');                   % <--- Eventually need to take out the global signal here

    % Mask(boldData, 'wm', 0, NaN);                     % <--- White matter & gray matter got switched again :(

    % Flatten the functional data set & get indices of NaN voxels
    funData = boldData.Data.Functional;
    funData = reshape(funData, [], size(funData, 4));
    funData(funData == 0) = NaN;
    idsNaN = isnan(funData(:, 1));

    % Calculate how many voxel signals should comprise each network signal (each has 10% of all voxels)
    numVoxels = sum(~idsNaN);
    numVoxelsPerNetwork = round(pctVoxelsPerNetwork*numVoxels);

    % Load the AAL labeled MNI brain & flatten it
    labeledIMG = load_nii([aalPath '/ROI_MNI_V4.nii']);
    voxelLabels = reshape(labeledIMG.img, [], 1);
    idsPrecuneus = (voxelLabels == idxROI);

    % Get the average ROI signal from the functional data array
    roiSignal = nanmean(funData(idsPrecuneus, :), 1);
    roiSignal = zscore(roiSignal);

    % Estimate correlation between the ROI signal & all BOLD voxels
    corrData = xcorrArr(funData, roiSignal, 'MaxLag', 0);
    sortedCorrData = sort(corrData(~idsNaN));

    % Generate & store a raw image of the correlation data for this subject/scan
    tempCorr = reshape(corrData, [91 109 91]);
    brainData = brainPlot('mri', tempCorr(:, :, round(linspace(1, 91, 21))),...
        'CLim', [-1 1],...
        'ColorbarLabel', 'r',...
        'YTickLabel', round(linspace(1, 91, 21)),...
        'YLabel', 'Slice Number');
    Store(brainData, 'Path', pwd, 'Name', sprintf('%d-%d Stationary Correlations', boldData.Subject, boldData.Scan), 'Overwrite', true);
    close(brainData);

    % Get the DMN & TPN voxel indices (top & bottom 10% of correlation coefficients)
    idsDMN = corrData >= sortedCorrData(end - numVoxelsPerNetwork + 1);
    idsTPN = corrData <= sortedCorrData(numVoxelsPerNetwork);

    % Store some temporary results to use later
    subject = boldData.Subject;
    scan = boldData.Scan;
    dataSaveName = sprintf('%d-%d_ThompsonAnalysisData.mat', subject, scan);
    save(dataSaveName, 'funData', 'idsNaN', 'corrData', 'idsDMN', 'idsTPN', 'subject', 'scan', '-v7.3');
    
    % Garbage collection
    clear boldData funData temp*;
    
    fprintf(1, 'Subject %d Scan %d formatted data saved.\n\n', subject, scan);
    
end
    


%% Run the Analysis
for a = 1:length(subjectsToRun)
    
    % Get sets of subject-specific formatted data
    subFileStr = sprintf('%d-\\d_ThompsonAnalysisData', subjectsToRun(a));
    subjectFiles = get(fileData(pwd, 'Search', subFileStr, 'Ext', '.mat'), 'Path');
    
    % Concatenate & average the RSN voxel indices
    idsDMNAll = [];
    idsTPNAll = [];
    for b = 1:length(subjectFiles)
        
        load(subjectFiles{b}, 'idsDMN', 'idsTPN');
        
        idsDMNAll = cat(2, idsDMNAll, idsDMN);
        idsTPNAll = cat(2, idsTPNAll, idsTPN);
        
    end
    idsDMN = nanmean(idsDMNAll, 2) > averageNetworkIdsThreshold;
    idsTPN = nanmean(idsTPNAll, 2) > averageNetworkIdsThreshold;
    
    % Generate average RSN signals & run SWC on them for each subject/scan
    for b = 1:length(subjectFiles)
        
        load(subjectFiles{b}, 'funData', 'subject', 'scan');
        
        % Get the DMN & TPN average signals
        dmnSignal = nanmean(funData(idsDMN, :), 1);
        tpnSignal = nanmean(funData(idsTPN, :), 1);

        % Z-Score the average network signals
        dmnSignal = zscore(dmnSignal);
        tpnSignal = zscore(tpnSignal);

        % Create & store a plot the average RSN time series
        fig = windowObj('Size', 'fullscreen'); 
        plot([dmnSignal' tpnSignal'], 'LineWidth', 4); 
        set(gca, 'FontSize', 15);
        legend('TPN Signal', 'DMN Signal');
        xlabel('Samples (TR)', 'FontSize', 20);
        title('Task Positive & Default Mode Average Signals', 'FontSize', 25);
        imSaveName = sprintf('%d-%d DMN & TPN Signals.png', subject, scan);
        saveas(fig.FigureHandle, imSaveName, 'png');
        close;

        % Initialize a SWC data array
        swcData = zeros(1, (length(dmnSignal) - windowLength)/(windowLength - windowOverlap));
            
        % SWC of the RSN time series
        d = 1;
        for c = 1:(windowLength - windowOverlap):length(dmnSignal) - windowLength
            tempCorr = corrcoef(dmnSignal(c:(c + windowLength - 1)), tpnSignal(c:(c + windowLength - 1)));
            swcData(d) = tempCorr(2, 1);
            d = d + 1;
        end
            
        % Create & store a plot of the SWC data over time
        fig = windowObj('Size', 'fullscreen'); 
        plot(swcData(b, :), 'LineWidth', 4);
        set(gca, 'FontSize', 15);
        xlabel('Samples (TR)', 'FontSize', 20);
        title('SWC between Task Positive & Default Mode ROI Signals', 'FontSize', 25);
        imSaveName = sprintf('%d-%d DMN & TPN SWC.png', subject, scan);
        saveas(fig.FigureHandle, imSaveName, 'png');
        close;

        dataSaveName = sprintf('%d-%d_ThompsonAnalysisResults.mat', subject, scan);
        save(dataSaveName, 'swcData', 'dmnSignal', 'tpnSignal', '-v7.3');
        
        % Garbage collection
        clear temp*
            
        fprintf(1, 'Subject %d Scan %d analysis complete.\n\n', subject, scan);
    end
    
end