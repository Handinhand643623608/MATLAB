%% 20140428 


%% 1138 - Sliding Window Correlation between EEG Electrodes

cle

% Specify signal comparison parameters (in seconds)
sigOffset = 0;
windowLength = 20;
overlap = windowLength - 2;

load masterStructs
eegPath = [fileStruct.Paths.DataObjects '/EEG/'];
eegStr = '_dcZ';

eegFiles = get(fileData(eegPath, 'search', eegStr), 'Path');

% Convert time units to sample units
sigOffset = sigOffset * 0.5;
windowLength = windowLength * 0.5;
overlap = overlap * 0.5;

corrData(8, 3) = struct(...
    'Data', [],...
    'OverlapSamples', overlap,...
    'SignalOffsetSamples', sigOffset,...
    'WindowLengthSamples', windowLength);
progbar = progress('Sliding Window Correlation', 'Scans Completed');
for a = 1:length(eegFiles)
    load(eegFiles{a});
    
    reset(progbar, 2);
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            % Calculate sliding window correlation
            ephysData = eegData(b).Data.EEG;
            for c = 1:(windowLength - overlap):size(ephysData, 2) - windowLength
                currentCorr = corrcoef(ephysData(:, c:c+windowLength-1)');                
                corrData(a, b).Data = cat(3, corrData(a, b).Data, currentCorr);
            end
        end
        update(progbar, 2, b/length(eegData));
    end
    update(progbar, 1, a/length(eegFiles));
end
close(progbar);

saveStr = sprintf('%s//swcData_EEG_(%i, %i, %i)_%s.mat',...
    fileStruct.Paths.Desktop,...
    overlap,...
    sigOffset,...
    windowLength,...
    datestr(now, 'yyyymmddTHHMM'));
save(saveStr, 'corrData', '-v7.3');


%% 1328 - Creating Movies of the Sliding Window Correlations
% cle
load masterStructs
% load([fileStruct.Paths.Desktop '/swcData_EEG_(4, 0, 5)_20140428T1511.mat']);
% load([fileStruct.Paths.Desktop '/swcData_EEG_(5, 0, 6)_20140501T1025.mat']);
load([fileStruct.Paths.Desktop '/swcData_EEG_(9, 0, 10)_20140428T1228.mat']);
% load([fileStruct.Paths.Desktop '/swcData_EEG_(19, 0, 20)_20140428T1231.mat']);
% load([fileStruct.Paths.Desktop '/swcData_EEG_(24, 0, 25)_20140428T1503.mat']);



% Initialize imaging variables
subjects = 1:8;
scans = 1;
cmap = jet(256);

for a = subjects
    for b = scans
        if ~isempty(corrData(a, b).Data)
            currentCorr = corrData(a, b).Data;
            currentCorr = scaleToRange(currentCorr, [1 256], [-1 1]);
            currentCorr = permute(currentCorr, [1 2 4 3]);
            corrMovie = immovie(currentCorr, jet(256));
            test = implay(corrMovie, 5);
        end
    end
end

% Results: These are pretty interesting. For each of the subjects, the infraslow EEG cycles between
% periods of large-scale synchronization and less synchronized states. Visibility of this phenomenon
% naturally depends on the window length that was used for SWC, but nevertheless it is visible for
% each of the lengths that have been run so far. The best visibility (and most stable large-scale
% correlation patterns) is achieved at window lengths of 50 seconds (25 samples). The
% synchronization happens so frequently, actually, that the strong positive inter-electrode
% correlations observed with stationary correlation are no longer all that surprising. 


%% 1416 - Generating Stationary Correlation Data between BOLD Global Signal & EEG Cluster Signals
% Had data for these once, but it's too old now and the method of EEG cluster signal regression
% changed since the last time they were run.
load masterStructs
boldPath = [fileStruct.Paths.DataObjects '/BOLD'];
eegPath = [fileStruct.Paths.DataObjects '/EEG'];
boldStr = '_dcZ';
eegStr = '_dcGRZ_';

boldFiles = get(fileData(boldPath, 'search', boldStr), 'Path');
eegFiles = get(fileData(eegPath, 'search', eegStr), 'Path');

corrData(8, 3) = struct(...
    'Data', [],...
    'ParentData', [],...
    'SampleShifts', [-10:1:10],...
    'TimeShifts', [-20:2:20]);
    
progbar = progress('Global-Cluster Signal Cross Correlation', 'Scans Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    
    reset(progbar, 2);
    for b = 1:length(boldData)
        
        currentGlobal = boldData(b).Data.Nuisance.Global;
        currentCluster = eegData(b).Data.Global;
        
        currentCorr = xcorrArr(currentCluster, currentGlobal, 'MaxLag', 10);
        
        corrData(a, b) = struct(...
            'Data', flipdim(currentCorr, 2),...             % <--- Flipped because EEG was first in the correlation function (because only the BOLD data is a vector)
            'ParentData', {{boldFiles(a), eegFiles(a)}},...
            'SampleShifts', [-10:1:10],...
            'TimeShifts', [-20:2:20]);
        update(progbar, 2, b/length(boldData));
    end
    update(progbar, 1, a/length(boldFiles));
end

save([fileStruct.Paths.Desktop '/corrData_Global-Cluster_' datestr(now, 'yyyymmddTHHMM') '.mat'], 'corrData', '-v7.3');        


%% 1424 - Imaging the Correlations Above
load masterStructs;
load([fileStruct.Paths.Desktop '/corrData_Global-Cluster_20140428T1433.mat']);
for a = 1:size(corrData, 1)
    for b = 1:size(corrData, 2)
        if ~isempty(corrData(a, b).Data)
            figure;
            for c = 1:size(corrData(a, b).Data, 1)
                subplot(size(corrData(a, b).Data, 1), 1, c)
                plot(corrData(a, b).TimeShifts, corrData(a, b).Data(c, :));
            end
        end
    end
end


% Results: Correlations between the global & cluster signals are all over the place. Correlation
% coefficients are rarely high (capping out at ~0.5) and more typically fall close to zero. Time
% shifts of maximum correlation are equally inconsistent. A few high peaks are observable at ~+10s
% (EEG predicting BOLD), and a couple are also observable at ~0s and lower. The lack of consistency
% suggests that the time series are at best transiently related, which is why the SWC analysis above
% from earlier today was started in the first place.
