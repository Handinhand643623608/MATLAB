%% 20140617 


%% 1356 - Running Stationary RSN-EEG Cross-Correlations 

load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ'), 'Path');
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');

% ccStruct = struct(...
%     'Initialization', struct(...
%         'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
%         'GSR', [false false],...
%         'Modalities', 'BOLD-EEG',...
%         'Relation', 'Partial Correlation',...
%         'ScanState', 'RS'),...
%     'Correlation', struct(...
%         'Control', 'BOLD Nuisance',...
%         'Channels', [],...
%         'Fs', 0.5,...
%         'GenerateNull', false,...
%         'Mask', [],...
%         'MaskThreshold', [],...
%         'Scans', [],...
%         'Subjects', [],...
%         'TimeShifts', [-20:2:20]),...
%     'Thresholding', struct(...
%         'AlphaVal', 0.05,...
%         'CDFMethod', 'arbitrary',...
%         'FWERMethod', 'sgof',...
%         'Mask', gmMask,...
%         'MaskThreshold', 0.7,...
%         'Parallel', 'gpu',...
%         'Tails', 'both'));

    
corrStruct(8, 2) = struct(...
    'Data', [],...
    'SampleLags', [],...
    'TimeLags', []);

pbar = progress('Cross-Correlating RSN-EEG Signals', '');
for a = 1:length(boldFiles)
    
    pbar.BarTitle{2} = 'Loading Data Sets';
    
    % Load the BOLD & EEG data
    load(boldFiles{a});
    load(eegFiles{a});
    
    % Get the names of available RSN time series
    rsnNames = fieldnames(boldData(1).Data.ICA);
    
    pbar.BarTitle{2} = 'Scans Completed';
    reset(pbar, 2);
    for b = 1:2         % <--- ICA data doesn't exist for subject 6 scan 3
        
        % Get the EEG data
        currentEEG = eegData(b).Data.EEG;
        
        for c = 1:length(rsnNames);
            % Get the RSN signal
            currentRSN = boldData(b).Data.ICA.(rsnNames{c});
            
            % Cross correlate & store
            [cxy, lags] = xcorrArr(currentRSN, currentEEG);
            corrStruct(a, b).Data.(rsnNames{c}) = cxy;
        end
        
        % Fill in the sample lags
        corrStruct(a, b).SampleLags = lags;
        
        update(pbar, 2, b/length(boldData));
    end
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);

save([fileStruct.Paths.Desktop '/201406171356 - RSN-EEG Correlations.mat'], 'corrStruct', '-v7.3');

% Plot parameters
shiftsToPlot = -20:2:20;

% Create a structure for the average correlation data
meanCorrStruct = struct(...
    'Data', [],...
    'SampleLags', corrStruct(1, 1).SampleLags,...
    'TimeLags', 2*corrStruct(1, 1).SampleLags);
rsnNames = fieldnames(corrStruct(1, 1).Data);

% Average data together
plotData = [];
for a = 1:length(rsnNames)
    catCorr = [];
    for b = 1:8
        for c = 1:2
            catCorr = cat(3, catCorr, corrStruct(b, c).Data.(rsnNames{a}));
        end
    end
    meanCorrStruct.Data.(rsnNames{a}) = nanmean(catCorr, 3);
    plotData = cat(3, plotData, meanCorrStruct.Data.(rsnNames{a}));
end

% Make a plot of the data
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
brainData = brainPlot('eeg', plotData(:, idsTimeShifts, :),...
    'Title', 'RSN-EEG Cross-Correlations',...
    'XLabel', 'Time(s)',...
    'XTickLabel', shiftsToPlot,...
    'YLabel', 'RSN',...
    'YTickLabel', rsnNames);

saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/201406171356 - RSN-EEG Cross-Correlations.png'], 'png');

% Results: These data actually look pretty different than the results from before (20130128, which apparently is the
% last time I ran this analysis). Although the images I have from then are missing several of the RSNs that are now
% included, those that can be compared tend to be dissimilar. Some similarities do exist between the images, such as
% correlations with: SMN, PVN, LVN, and DAN. The unknown networks and CSF networks are incomparable between the images
% (they're split up differently between the two data sets). 
%
% It's still not clear what to make of these images. I think it was originally hoped that the EEG correlates would form
% distinct topologies that would be unique to some or all RSNs. That way, there would be a clear way to use EEG data to
% study RSN activities. The results we've been getting on this analysis aren't nearly as clear-cut as that approach
% would require. Patterns of correlation are messy and often smeared across 10s or so of time shifts. There is also
% overlap that exists in the patterns between certain RSNs, which would complicate or render impossible assigning
% specific patterns to specific RSNs. 
%
% A few patterns exhibit the change in sign over time that we've observed in other data. I think we've basically come to
% assume that this phenomenon is related to QPPs, and these data don't refute that notion. Switching frequencies are a
% little inconsistent, but by visual inspection appear to be around 10s when they do occur (plus or minus a few
% seconds). See the SMN, LVN, PVN (sort of), and WM correlates for examples. They may happen in a couple of other RSNs
% as well, but it's less clear. 
%
% Much of this data looks as if it would not survive significance thresholding. Correlation values are universally low
% at around 0.2-0.3 at the highest. These should be z-scored, but with such low magnitudes I don't think it will make
% any real difference. Will have to threshold these data to know for sure.
%
% An idea that just struck me would be to run this analysis after having regressed the BOLD nuisance signals from EEG
% data. I'm going to try that now.



%% 1539 - Re-Running RSN-EEG Cross-Correlations, Regressing BOLD Nuisance Signals from EEG
% Regressing BOLD nuisance signals from the EEG data actually made a noticeable difference in the stationary
% correlations between signals of both modalities. It could be that it will here too. If BOLD nuisance signals are
% influencing the EEG data, then this noise could be influencing the correlations that we observe with some or all
% resting state networks. By regressing noise estimates, the residual EEG signals should be closer to pure neuronal
% activity (at least in theory) and their relationship with RSN signals may be a little less ambiguous (because some
% common mode noise will now be gone). If however the nuisance signals are not really influencing the EEG data, the
% regression shouldn't change the data too much. In that case, these results will look mostly similar the ones above.
% This will not be a partial correlation analysis; presumably all nuisance influences on the RSN activity are removed
% via ICA. Nuisance signals will therefore only be removed from EEG data.

% Get the EEG & BOLD data for the analysis
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ'), 'Path');
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');
    
% Create a structure for holding the correlation data
corrStruct(8, 2) = struct(...
    'Data', [],...
    'SampleLags', [],...
    'TimeLags', []);

% Create strings for identifying nuisance data
nuisanceStrs = {'Motion', 'Global', 'WM', 'CSF'};

pbar = progress('Cross-Correlating RSN-EEG Signals', '');
for a = 1:length(boldFiles)
    
    pbar.BarTitle{2} = 'Loading Data Sets';
    
    % Load the BOLD & EEG data
    load(boldFiles{a});
    load(eegFiles{a});
    
    % Get the names of available RSN time series
    rsnNames = fieldnames(boldData(1).Data.ICA);
    
    pbar.BarTitle{2} = 'Scans Completed';
    reset(pbar, 2);
    for b = 1:2         % <--- ICA data doesn't exist for subject 6 scan 3

        % Get the BOLD nuisance signals
        nuisanceData = ones(size(eegData(b).Data.EEG, 2), 1);
        for c = 1:length(nuisanceStrs)
            currentNuisance = boldData(b).Data.Nuisance.(nuisanceStrs{c});
            if any(strcmpi(nuisanceStrs{c}, {'Global', 'WM'}))
                currentNuisance = cat(2, currentNuisance(3:end), zeros(1, 2));
            end
            nuisanceData = cat(2, nuisanceData, currentNuisance');
        end
           
        % Regress BOLD nuisance signals from EEG data
        Regress(eegData(b), nuisanceData);
        
        % Get the EEG data
        currentEEG = eegData(b).Data.EEG;
        
        for c = 1:length(rsnNames);
            % Get the RSN signal
            currentRSN = boldData(b).Data.ICA.(rsnNames{c});
            
            % Cross correlate & store
            [cxy, lags] = xcorrArr(currentRSN, currentEEG);
            corrStruct(a, b).Data.(rsnNames{c}) = cxy;
        end
        
        % Fill in the sample lags
        corrStruct(a, b).SampleLags = lags;
        
        update(pbar, 2, b/length(boldData));
    end
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);

% Save the correlation data
save([fileStruct.Paths.Desktop '/201406171539 - RSN-EEG Correlations.mat'], 'corrStruct', '-v7.3');

% Plot parameters
shiftsToPlot = -20:2:20;

% Create a structure for the average correlation data
meanCorrStruct = struct(...
    'Data', [],...
    'SampleLags', corrStruct(1, 1).SampleLags,...
    'TimeLags', 2*corrStruct(1, 1).SampleLags);
rsnNames = fieldnames(corrStruct(1, 1).Data);

% Average data together
plotData = [];
for a = 1:length(rsnNames)
    catCorr = [];
    for b = 1:8
        for c = 1:2
            catCorr = cat(3, catCorr, corrStruct(b, c).Data.(rsnNames{a}));
        end
    end
    meanCorrStruct.Data.(rsnNames{a}) = nanmean(catCorr, 3);
    plotData = cat(3, plotData, meanCorrStruct.Data.(rsnNames{a}));
end

% Make a plot of the data
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
brainData = brainPlot('eeg', plotData(:, idsTimeShifts, :),...
    'Title', 'RSN-EEG Cross-Correlations (BOLD Nuisance Regressed)',...
    'XLabel', 'Time(s)',...
    'XTickLabel', shiftsToPlot,...
    'YLabel', 'RSN',...
    'YTickLabel', rsnNames);

% Save an image of the data
saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/201406171539 - RSN-EEG Cross-Correlations.png'], 'png');

% Results: Average correlates look very similar to results from earlier today, but with one big difference: there are
% far fewer high-magnitude correlations across the map. Importantly, correlation with several noise-like ICs is
% dramatically reduced (see CSF, WM, and unknowns). Unfortunately, strong correlations with real-looking RSNs is also
% dramatically reduced (see SMN, LLN, RLN, salience, and DAN). 
%
% This may be related to the increase in focal correlations that I was seeking (the LVN and PVN are curious examples to
% the contrary), but it's unknown if this approach has yielded trustworthy results. There are several instances of
% introduced anticorrelations and, if the results from above look unlikely to pass significance testing, then these
% almost certainly won't. Magnitudes now almost never exceed 0.15 and by visual inspection appear to be nearly zero
% almost everywhere. 
%
% It occurs to me that the average nuisance signals being used as regressors might not be the best approach here. They
% were helpful between pure signals of both modalities presumably because their contribution to both sets of signals was
% much more comparable. In other words, regressing them had a similar effect on both data sets. However, for this
% analysis here some (possibly all) RSNs conceivably rely on brain activity that is being captured and removed vis the
% blunt instrument that is average signal regression. Thus, what could work better would be to remove ICs that are noise
% estimates.



%% 1705 - Re-Running RSN-EEG Cross Correlations, Regressing BOLD Motion & Global Signal, & ICA WM & CSF Signals
% Get the EEG & BOLD data for the analysis
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ'), 'Path');
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');
    
% Create a structure for holding the correlation data
corrStruct(8, 2) = struct(...
    'Data', [],...
    'SampleLags', [],...
    'TimeLags', []);

% Create strings for identifying nuisance data
nuisanceStrs = {'Motion', 'Global', 'WM', 'CSF'};

pbar = progress('Cross-Correlating RSN-EEG Signals', '');
for a = 1:length(boldFiles)
    
    pbar.BarTitle{2} = 'Loading Data Sets';
    
    % Load the BOLD & EEG data
    load(boldFiles{a});
    load(eegFiles{a});
    
    % Get the names of available RSN time series
    rsnNames = fieldnames(boldData(1).Data.ICA);
    
    pbar.BarTitle{2} = 'Scans Completed';
    reset(pbar, 2);
    for b = 1:2         % <--- ICA data doesn't exist for subject 6 scan 3

        % Get the BOLD nuisance signals
        nuisanceData = ones(size(eegData(b).Data.EEG, 2), 1);
        for c = 1:length(nuisanceStrs)
            if any(strcmpi(nuisanceStrs{c}, {'Motion', 'Global'}))
                currentNuisance = boldData(b).Data.Nuisance.(nuisanceStrs{c});
            else
                currentNuisance = boldData(b).Data.ICA.(nuisanceStrs{c});
            end
            
            % Remove 4s from global & white matter signals so they match the EEG data better
            if any(strcmpi(nuisanceStrs{c}, {'Global', 'WM'}))
                currentNuisance = cat(2, currentNuisance(3:end), zeros(1, 2));
            end
            nuisanceData = cat(2, nuisanceData, currentNuisance');
        end
           
        % Regress BOLD nuisance signals from EEG data
        Regress(eegData(b), nuisanceData);
        
        % Get the EEG data
        currentEEG = eegData(b).Data.EEG;
        
        for c = 1:length(rsnNames);
            % Get the RSN signal
            currentRSN = boldData(b).Data.ICA.(rsnNames{c});
            
            % Cross correlate & store
            [cxy, lags] = xcorrArr(currentRSN, currentEEG);
            corrStruct(a, b).Data.(rsnNames{c}) = cxy;
        end
        
        % Fill in the sample lags
        corrStruct(a, b).SampleLags = lags;
        
        update(pbar, 2, b/length(boldData));
    end
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);

% Save the correlation data
save([fileStruct.Paths.Desktop '/201406171705 - RSN-EEG Correlations.mat'], 'corrStruct', '-v7.3');

% Plot parameters
shiftsToPlot = -20:2:20;

% Create a structure for the average correlation data
meanCorrStruct = struct(...
    'Data', [],...
    'SampleLags', corrStruct(1, 1).SampleLags,...
    'TimeLags', 2*corrStruct(1, 1).SampleLags);
rsnNames = fieldnames(corrStruct(1, 1).Data);

% Average data together
plotData = [];
for a = 1:length(rsnNames)
    catCorr = [];
    for b = 1:8
        for c = 1:2
            catCorr = cat(3, catCorr, corrStruct(b, c).Data.(rsnNames{a}));
        end
    end
    meanCorrStruct.Data.(rsnNames{a}) = nanmean(catCorr, 3);
    plotData = cat(3, plotData, meanCorrStruct.Data.(rsnNames{a}));
end

% Make a plot of the data
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
brainData = brainPlot('eeg', plotData(:, idsTimeShifts, :),...
    'Title', 'RSN-EEG Cross-Correlations (IC Nuisance Regressed)',...
    'XLabel', 'Time(s)',...
    'XTickLabel', shiftsToPlot,...
    'YLabel', 'RSN',...
    'YTickLabel', rsnNames);

% Save an image of the data
saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/201406171705 - RSN-EEG Cross-Correlations.png'], 'png');



%% 1753 - Re-Running RSN-EEG Cross Correlations Immediately Above, Without Regressing Global Signal
% Get the EEG & BOLD data for the analysis
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'search', '_dcZ'), 'Path');
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'search', '_dcZ'), 'Path');
    
% Create a structure for holding the correlation data
corrStruct(8, 2) = struct(...
    'Data', [],...
    'SampleLags', [],...
    'TimeLags', []);

% Create strings for identifying nuisance data
nuisanceStrs = {'Motion', 'WM', 'CSF'};

pbar = progress('Cross-Correlating RSN-EEG Signals', '');
for a = 1:length(boldFiles)
    
    pbar.BarTitle{2} = 'Loading Data Sets';
    
    % Load the BOLD & EEG data
    load(boldFiles{a});
    load(eegFiles{a});
    
    % Get the names of available RSN time series
    rsnNames = fieldnames(boldData(1).Data.ICA);
    
    pbar.BarTitle{2} = 'Scans Completed';
    reset(pbar, 2);
    for b = 1:2         % <--- ICA data doesn't exist for subject 6 scan 3

        % Get the BOLD nuisance signals
        nuisanceData = ones(size(eegData(b).Data.EEG, 2), 1);
        for c = 1:length(nuisanceStrs)
            if any(strcmpi(nuisanceStrs{c}, 'Motion'))
                currentNuisance = boldData(b).Data.Nuisance.(nuisanceStrs{c});
            else
                currentNuisance = boldData(b).Data.ICA.(nuisanceStrs{c});
            end
            
            % Remove 4s from global & white matter signals so they match the EEG data better
            if any(strcmpi(nuisanceStrs{c}, {'Global', 'WM'}))
                currentNuisance = cat(2, currentNuisance(3:end), zeros(1, 2));
            end
            nuisanceData = cat(2, nuisanceData, currentNuisance');
        end
           
        % Regress BOLD nuisance signals from EEG data
        Regress(eegData(b), nuisanceData);
        
        % Get the EEG data
        currentEEG = eegData(b).Data.EEG;
        
        for c = 1:length(rsnNames);
            % Get the RSN signal
            currentRSN = boldData(b).Data.ICA.(rsnNames{c});
            
            % Cross correlate & store
            [cxy, lags] = xcorrArr(currentRSN, currentEEG);
            corrStruct(a, b).Data.(rsnNames{c}) = cxy;
        end
        
        % Fill in the sample lags
        corrStruct(a, b).SampleLags = lags;
        
        update(pbar, 2, b/length(boldData));
    end
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);

% Save the correlation data
save([fileStruct.Paths.Desktop '/201406171753 - RSN-EEG Correlations.mat'], 'corrStruct', '-v7.3');

% Plot parameters
shiftsToPlot = -20:2:20;

% Create a structure for the average correlation data
meanCorrStruct = struct(...
    'Data', [],...
    'SampleLags', corrStruct(1, 1).SampleLags,...
    'TimeLags', 2*corrStruct(1, 1).SampleLags);
rsnNames = fieldnames(corrStruct(1, 1).Data);

% Average data together
plotData = [];
for a = 1:length(rsnNames)
    catCorr = [];
    for b = 1:8
        for c = 1:2
            catCorr = cat(3, catCorr, corrStruct(b, c).Data.(rsnNames{a}));
        end
    end
    meanCorrStruct.Data.(rsnNames{a}) = nanmean(catCorr, 3);
    plotData = cat(3, plotData, meanCorrStruct.Data.(rsnNames{a}));
end

% Make a plot of the data
idsTimeShifts = ismember(meanCorrStruct.TimeLags, shiftsToPlot);
brainData = brainPlot('eeg', plotData(:, idsTimeShifts, :),...
    'Title', 'RSN-EEG Cross-Correlations (IC Nuisance Regressed, GS Not Regressed)',...
    'XLabel', 'Time(s)',...
    'XTickLabel', shiftsToPlot,...
    'YLabel', 'RSN',...
    'YTickLabel', rsnNames);

% Save an image of the data
saveas(brainData.FigureHandle, [fileStruct.Paths.Desktop '/201406171753 - RSN-EEG Cross-Correlations.png'], 'png');