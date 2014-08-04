function ai_corrEG(fileStruct, paramStruct)

%% Initialize
% Assign inputs
assignInputs(fileStruct.analysis.xcorr.EEG_Global, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_Global, 'createOnly')

% Initialize function-specific parameters
visibleFigs = visibleFigs;

% Initialize the folder structure for saving images
masterSaveDir = [savePathImage '\' saveID];
if imageSingleSubjects
    firstLevel = {...
        'Mean Images', [];...
        'Mean Thresholded Images', [];...
        'Subject', subjects};
    secondLevel = {'Scan', 'Subject', scans};
else
    firstLevel = {'Mean Images', []; 'Mean Thresholded Images', []};
    secondLevel = [];
end
folderStruct = createNestedFolders(...
    'inPath', masterSaveDir,...
    'firstLevel', firstLevel,...
    'secondLevel', secondLevel);

% Initialize parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end
    

%% Image the Raw Cross-Correlation Data
if imageSingleSubjects    
    % Load the raw cross-correlation data
    corrLoadStr = ['corrData_' saveTag '_EEG-Global_' saveID '.mat'];
    load(corrLoadStr)

    % Initialize section-specific parameters
    if ~exist('imageShifts', 'var')
        imageShifts = corrData(1, 1).info.shiftsTime;
    end
    shiftsTimeAll = corrData(1, 1).info.shiftsTime;

    progressbar('Imaging Raw Correlation', 'Imaging Scans')
    for i = subjects
        progressbar([], 0)
        for j = scans{i}
            currentChannels = corrData(i, j).info.channels;

            % Get the data to be imaged
            currentCorr = corrData(i, j).data;

            switch parallelSwitch
                case true
                    parfor L = 1:length(imageShifts)
                        m = L;
                        % Produce the images
                        u_colormap_EEG(currentCorr(:, (shiftsTimeAll == imageShifts(L))), currentChannels,...
                            'backgroundColor', 'k',...
                            'circleColor', 'w',...
                            'colorMap', jet(256),...
                            'colorBounds', [-0.5 0.5],...
                            'figureSize', 'default',...
                            'visibleFigs', visibleFigs);
                        currentTitleStr = sprintf('Subject %d Scan %d EEG-BOLD Global Signal Raw Cross-Correlation (%d s Time Shift)', i, j, imageShifts(L));
                        title(currentTitleStr, 'Color', 'w')

                        % Save in the appropriate folder
                        currentSavePath = folderStruct.Subject.(num2word(i)).Scan.(num2word(j));
                        currentSaveName = sprintf('%04d', m);
                        currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
                        saveas(gcf, currentSaveStr, 'png')
                        close
                    end

                otherwise
                    m = 1;
                    for L = 1:length(imageShifts)
                        % Produce the images
                        u_colormap_EEG(currentCorr(:, (shiftsTimeAll == imageShifts(L))), currentChannels,...
                            'backgroundColor', 'k',...
                            'circleColor', 'w',...
                            'colorMap', jet(256),...
                            'colorBounds', [-0.5 0.5],...
                            'figureSize', 'default',...
                            'visibleFigs', visibleFigs);
                        currentTitleStr = sprintf('Subject %d Scan %d EEG-BOLD Global Signal Raw Cross-Correlation (%d s Time Shift)', i, j, imageShifts(L));
                        title(currentTitleStr, 'Color', 'w')

                        % Save in the appropriate folder
                        currentSavePath = folderStruct.Subject.(num2word(i)).Scan.(num2word(j));
                        currentSaveName = sprintf('%04d', m);
                        currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
                        saveas(gcf, currentSaveStr, 'png')
                            m = m + 1;
                        close
                    end
            end
            progressbar([], j/length(scans{i}))
        end
        progressbar(find(subjects == i)/length(subjects), [])
    end

    % Garbage collect
    clear corrData current*
    
end


%% Image the Raw Mean & Thresholded Mean Cross-Correlation Data
% Load the mean cross-correlation data
meanLoadStr = ['meanCorrData_' saveTag '_EEG-Global_' saveID '.mat'];
load(meanLoadStr);

% Initialize section-specific data
eegLabels = meanCorrData.info.channels;

% progressbar('Component Correlations Imaged')
corrData = zeros(length(eegLabels), length(imageShifts));
threshCorrData = corrData;

% Concatenate the correlation & thresholded correlation data
% Get the correlation data to be imaged
currentCorr = meanCorrData.data;
currentCorr = currentCorr(:, ismember(shiftsTime, imageShifts));
currentCutoffs =  meanCorrData.info.cutoffs;

% Initialize the thresholded correlation data
currentThreshCorr = currentCorr;
currentThreshCorr(currentThreshCorr >= currentCutoffs(1) & currentThreshCorr <= currentCutoffs(2)) = 0;

m = 1;
progressbar('Imaging Average EEG-Global Correlations')
for i = 1:length(imageShifts)
    % Image the average correlation data
    u_colormap_EEG(currentCorr(:, i), eegLabels,...
        'backgroundColor', 'k',...
        'circleColor', 'w',...
        'colorMap', jet(256),...
        'colorBounds', [-0.2 0.2],...
        'figureSize', 'default',...
        'visibleFigs', visibleFigs);
    
    currentTitleStr = sprintf('EEG-BOLD Global Signal Average Correlations (%d s Time Shift)', imageShifts(i));
    title(currentTitleStr, 'Color', 'w')
    currentSavePath = folderStruct.MeanImages.root;
    currentSaveName = sprintf('%04d', m);
    currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
    saveas(gcf, currentSaveStr, 'png')
        m = m + 1;
    close
    
    % Image the average correlation data
    u_colormap_EEG(currentThreshCorr(:, i), eegLabels,...
        'backgroundColor', 'k',...
        'circleColor', 'w',...
        'colorMap', jet(256),...
        'colorBounds', [-0.2 0.2],...
        'figureSize', 'default',...
        'visibleFigs', visibleFigs);
    
    currentTitleStr = sprintf('EEG-BOLD Global Signal Thresholded Average Correlations (%d s Time Shift)', imageShifts(i));
    title(currentTitleStr, 'Color', 'w')
    currentSavePath = folderStruct.MeanThresholdedImages.root;
    currentSaveName = sprintf('%04d', m);
    currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
    saveas(gcf, currentSaveStr, 'png')
        m = m + 1;
    close
    progressbar(i/length(imageShifts))
end

% Garbage collect
clear current* meanCorrData

if matlabpool('size') ~= 0
    matlabpool close
end