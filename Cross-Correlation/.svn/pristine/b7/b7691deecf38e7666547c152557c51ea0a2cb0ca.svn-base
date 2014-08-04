function ai_corrEI(fileStruct, paramStruct)

%% Initialize
% Assign inputs
assignInputs(fileStruct.analysis.xcorr.EEG_IC, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_IC, 'createOnly')

% Initialize function-specific parameters
components = paramStruct.ICA.componentIdents;
visibleFigs = visibleFigs;

% Initialize the folder structure for saving images
masterSaveDir = [savePathImage '\' saveID];
for i = 1:length(components)
    inPath = [masterSaveDir '\' components{i}];
    firstLevel = {...
        'Mean Images', [];...
        'Mean Thresholded Images', [];...
        'Subject', subjects};
    secondLevel = {'Scan', 'Subject', scans};
    folderStruct.(components{i}) = createNestedFolders(...
        'inPath', inPath,...
        'firstLevel', firstLevel,...
        'secondLevel', secondLevel);
end

% Initialize parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end
    

%% Image the Raw Cross-Correlation Data
if imageSingleSubjects    
    % Load the raw cross-correlation data
    corrLoadStr = ['corrData_EEG_IC_' saveTag '_' saveID '.mat'];
    load(corrLoadStr)

    % Initialize section-specific parameters
    if ~exist('imageShifts', 'var')
        imageShifts = corrData(1, 1).info.shiftsTime;
    end
    shiftsTimeAll = corrData(1, 1).info.shiftsTime;

    progressbar('Raw Correlation Image Generation', 'Scans Completed', 'Components Completed')
    for i = subjects
        progressbar([], 0, [])
        for j = scans{i}
            currentChannels = corrData(i, j).info.channels;

            progressbar([], [], 0)
            for k = 1:length(components)
                % Get the data to be imaged
                currentCorr = corrData(i, j).data.(components{k});

                switch parallelSwitch
                    case true
                        parfor L = 1:length(imageShifts)
                            m = k*i + L;
                            % Produce the images
                            u_colormap_EEG(currentCorr(:, (shiftsTimeAll == imageShifts(L))), currentChannels,...
                                'backgroundColor', 'k',...
                                'circleColor', 'w',...
                                'colorMap', jet(256),...
                                'colorBounds', [-0.5 0.5],...
                                'figureSize', 'halfScreen',...
                                'visibleFigs', visibleFigs);
                            currentTitleStr = sprintf('Subject %d Scan %d EEG-%s Raw Cross-Correlation (%d s Time Shift)', i, j, components{k}, -imageShifts(L));
                            title(currentTitleStr)

                            % Save in the appropriate folder
                            currentSavePath = folderStruct.(components{k}).Subject.(num2word(i)).Scan.(num2word(j));
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
                                'figureSize', 'halfScreen',...
                                'visibleFigs', visibleFigs);set(gcf, 'Visible', visibleFigs)
                            currentTitleStr = sprintf('Subject %d Scan %d EEG-%s Raw Cross-Correlation (%d s Time Shift)', i, j, components{k}, -imageShifts(L));
                            title(currentTitleStr)

                            % Save in the appropriate folder
                            currentSavePath = folderStruct.(components{k}).Subject.(num2word(i)).Scan.(num2word(j));
                            currentSaveName = sprintf('%04d', m);
                            currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
                            saveas(gcf, currentSaveStr, 'png')
                                m = m + 1;
                            close
                        end
                end
                progressbar([], [], k/length(components))
            end
            progressbar([], j/length(scans{i}), [])
        end
        progressbar(find(subjects == i)/length(subjects), [], [])
    end

    % Garbage collect
    clear corrData current*
    
end


%% Image the Raw Mean & Thresholded Mean Cross-Correlation Data
% Load the mean cross-correlation data
meanLoadStr = ['meanCorrData_EEG_IC_' saveTag '_' saveID '.mat'];
load(meanLoadStr);

% Initialize section-specific data
eegLabels = meanCorrData.info.channels;

% progressbar('Component Correlations Imaged')
corrData = zeros(length(eegLabels), length(imageShifts), length(components));
threshCorrData = corrData;

% Concatenate the correlation & thresholded correlation data
for i = 1:length(components)
    % Get the correlation data to be imaged
    currentCorr = meanCorrData.data.(components{i});
    currentCorr = currentCorr(:, ismember(shiftsTime, imageShifts));
    currentCutoffs =  meanCorrData.info.cutoffs.(components{i});
    
    % Initialize the thresholded correlation data
    currentThreshCorr = currentCorr;
    currentThreshCorr(currentThreshCorr >= currentCutoffs(1) & currentThreshCorr <= currentCutoffs(2)) = 0;
    
    % Concatenate the data
    corrData(:, :, i) = currentCorr;
    threshCorrData(:, :, i) = currentThreshCorr;
end

% Image the correlation data
u_dataMontage(corrData,...
    'axesColor', 'w',...
    'backgroundColor', 'k',...
    'circleColor', 'w',...
    'colorBounds', [-0.2 0.2],...
    'colorMap', jet(256),...
    'dataType', 'EEG',...
    'eegLabels', eegLabels,...
    'fontColor', 'w',...
    'plotTitle', 'EEG-RSN Average Cross Correlations',...
    'spacing', 0.05,...
    'xTitle', 'Time Shifts (s)',...
    'xTickLabels', imageShifts,...
    'yTitle', 'Resting State Networks',...
    'yTickLabels', components);

% Save the montage as scalable graphics to PDF & EPS
set(gcf,...
    'InvertHardcopy', 'off',...
    'Renderer', 'painters',...
    'Units', 'inches')
currentPosition = get(gcf, 'Position');
currentPosition(1:2) = 0;
set(gcf,...
    'PaperSize', currentPosition(3:4),...
    'PaperPosition', currentPosition);
saveas(gcf, [masterSaveDir '\Montage.pdf'], 'pdf');
saveas(gcf, [masterSaveDir '\Montage.eps'], 'eps');

% Image the thresholded correlation data
u_dataMontage(threshCorrData,...
    'axesColor', 'w',...
    'backgroundColor', 'k',...
    'circleColor', 'w',...
    'colorBounds', [-0.2 0.2],...
    'colorMap', jet(256),...
    'dataType', 'EEG',...
    'eegLabels', eegLabels,...
    'fontColor', 'w',...
    'plotTitle', 'EEG-RSN Average Thresholded Cross Correlations',...
    'spacing', 0.05,...
    'xTitle', 'Time Shifts (s)',...
    'xTickLabels', imageShifts,...
    'yTitle', 'Resting State Networks',...
    'yTickLabels', components);
    
% Save the montage as scalable graphics to PDF & EPS
set(gcf,...
    'InvertHardcopy', 'off',...
    'Renderer', 'painters',...
    'Units', 'inches')
currentPosition = get(gcf, 'Position');
currentPosition(1:2) = 0;
set(gcf,...
    'PaperSize', currentPosition(3:4),...
    'PaperPosition', currentPosition);
saveas(gcf, [masterSaveDir '\Thresholded Montage.pdf'], 'pdf');
saveas(gcf, [masterSaveDir '\Thresholded Montage.eps'], 'eps');

% Garbage collect
clear current* meanCorrData

if matlabpool('size') ~= 0
    matlabpool close
end