%% 20130922

%% 1611
% Thresholded correlations just finished running. Generating & saving thresholded images now
load masterStructs
ccPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG'];
searchStr = 'meanPartialCorrObject_.*_dcCSRZ';
ccFiles = get(fileData(ccPath, 'search', searchStr), 'Path');

for a = 1:length(ccFiles)
    load(ccFiles{a});
    brainData = plot(meanCorrData, 'CLim', [-3 3]);
    brainData(2) = plot(meanCorrData, 'CLim', [-3 3], 'Thresholding', 'on');
    store(brainData, 'ext', {'png', 'fig', 'pdf'});
    close(brainData)
end


%% 1903
% Now need to calculate BOLD nuisance - EEG correlations
load masterStructs
boldSearchStr = 'dcZ';
eegSearchStr = 'dcGRZ';
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', boldSearchStr), 'Path');
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', eegSearchStr), 'Path');

channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};
nuisanceStrs = {'Motion', 'Global', 'WM', 'CSF'};

currentCorr(8, 3) = struct('C3', [], 'FPZ', [], 'PO8', [], 'PO10', [], 'AF7', []);
progBar = progress('Subjects Processed', 'Scans Processed');
for a = 1:length(boldFiles)
    % Load data sets
    load(boldFiles{a});
    load(eegFiles{a});
    
    reset(progBar, 2);
    for b = 1:length(boldData)
        
        % Gather nuisance signals
        currentNuisance = [];
        for c = 1:length(nuisanceStrs) 
            currentNuisance = cat(1, currentNuisance, boldData(b).Data.Nuisance.(nuisanceStrs{c}));
        end
    
        % Cross correlate nuisance signals with channel data & store
        for c = 1:length(channels)
            [currentCorr(a, b).(channels{c}), currentCorr(a, b).Shifts] = xcorrArr(...
                currentNuisance,...
                eegData(b).Data.EEG(strcmpi(eegData(b).Channels, channels{c}), :),...
                'MaxLag', 10);
            
            % Normalized Fisher's transform
            currentCorr(a, b).(channels{c}) = atanh(currentCorr(a, b).(channels{c})).*sqrt(size(currentNuisance, 2) - 3);
        end
        update(progBar, 2, b/length(boldData));
    end
    update(progBar, 1, a/length(boldFiles));
end
close(progBar);


%% 1919
% Average together the data
meanCorr = struct('C3', [], 'FPZ', [], 'PO8', [], 'PO10', [], 'AF7', []);
for a = 1:length(channels)
    currentMean = [];
    for b = 1:size(currentCorr, 1)
        for c = 1:size(currentCorr, 2)
            if ~isempty(currentCorr(b, c).C3)
                currentMean = cat(3, currentMean, currentCorr(b, c).(channels{a}));
            end
        end
    end
    meanCorr.(channels{a}).Mean = nanmean(currentMean, 3);
    meanCorr.(channels{a}).SEM = nanstd(currentMean, [], 3)./sqrt(size(currentMean, 3));
end

%% 1920
% Plot the data
deskPath = fileStruct.Paths.Desktop;
corrSavePath = [deskPath '/Nuisance-EEG Correlation'];
for a = 1:length(channels)
    currentMean = meanCorr.(channels{a}).Mean;
    currentSEM = meanCorr.(channels{a}).SEM;
    
    for b = 1:size(currentMean, 1);
        shadePlot(...
            currentCorr(1, 1).Shifts./0.5,...
            currentMean(b, :),...
            currentSEM(b, :));
        
        if ismember(b, 1:6)
            titleStr = ['BOLD Motion-' channels{a} ' Cross Correlation'];
            saveStr = ['Motion ' num2str(b) ' ' channels{a} '.png'];
            savePath = [corrSavePath '/Motion'];
            if ~exist(savePath, 'dir'); mkdir(savePath); end;
        else
            titleStr = ['BOLD ' nuisanceStrs{b-5} '-' channels{a} ' Cross Correlation'];
            saveStr = [nuisanceStrs{b-5} ' ' channels{a} '.png'];
            savePath = [corrSavePath '/' nuisanceStrs{b-5}];
            if ~exist(savePath, 'dir'); mkdir(savePath); end;
        end
        title(titleStr, 'FontSize', 16);
        xlabel('Time Shifts (s)', 'FontSize', 14);
        ylabel('Z-Scores', 'FontSize', 14);
        saveas(gcf, [savePath '/' saveStr], 'png');
        close
    end
end