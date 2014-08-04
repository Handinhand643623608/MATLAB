function f_CA_image_xcorrEI(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
if isempty(paramStruct.xcorr.BLP_IC.alpha.subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.xcorr.BLP_IC.alpha.subjects;
    scans = paramStruct.xcorr.BLP_IC.alpha.scans;
end
components = paramStruct.ICA.componentIdents;
colorBoundsRaw = paramStruct.xcorr.BLP_IC.alpha.colorBoundsRaw;
colorBoundsMean = paramStruct.xcorr.BLP_IC.alpha.colorBoundsMean;
bandStr = 'Alpha';

% Initialize the folder structure for saving outputs
saveDir = [fileStruct.paths.analyses '\Cross-Correlation\BLP-IC\' bandStr];
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
saveDirsComponents = cell(length(components), 1);
saveDirsRaw = cell(length(components), 1);
saveDirsMean = cell(length(components), 1);
saveDirsThresh = cell(length(components), 1);
for i = 1:length(components)
    saveDirsComponents{i} = [saveDir '\' components{i}];
    if ~exist(saveDirsComponents{i}, 'dir')
        mkdir(saveDirsComponents{i});
    end
    saveDirsRaw{i} = u_CA_create_folders('Raw', saveDirsComponents{i}, subjects, scans);
    saveDirsMean{i} = [saveDirsComponents{i} '\Mean'];
    if ~exist(saveDirsMean{i}, 'dir')
        mkdir(saveDirsMean{i});
    end
    saveDirsThresh{i} = [saveDirsComponents{i} '\Mean Thresholded'];
    if ~exist(saveDirsThresh{i}, 'dir')
        mkdir(saveDirsThresh{i});
    end
end
    
%% Image the Raw Cross-Correlation Data
% Load the raw cross-correlation data
load corrData_BLP_IC_alpha

% Initialize section-specific parameters
shiftsTime = corrData(1, 1).info.timeShifts;

% m = 1;
% for i = subjects
%     for j = scans{i}
%         for k = 1:length(components)
%             % Get the data to be imaged
%             currentCorr = corrData(i, j).data.(components{k});
%             
%             for L = 1:length(shiftsTime)
%                 % Produce the images
%                 f_EEG_colormap(currentCorr(:, L), corrData(i, j).info.channels, colorBoundsRaw);
%                 currentTitleStr = sprintf('Subject %d Scan %d %s BLP-%s Raw Cross-Correlation (%d s Time Shift)', i, j, bandStr, components{k}, -shiftsTime(L));
%                 title(currentTitleStr)
%                 
%                 % Save in the appropriate folder
%                 currentSaveName = sprintf('%04d', m);
%                     m = m + 1;
%                 currentSaveStr = [saveDirsRaw{k}{i}{j} '\' currentSaveName '.png'];
%                 saveas(gcf, currentSaveStr, 'png')
%                 close
%             end
%         end
%     end
% end

% Garbage collect
clear corrData current*

%% Image the Raw Mean & Thresholded Mean Cross-Correlation Data
% Load the mean cross-correlation data
load meanCorrData_BLP_IC_alpha

% Initialize section-specific variables
shiftsTime = meanCorrData.info.timeShifts;

m = 1;
for i = 1:length(components)
    for j = 1:length(shiftsTime)
        % Get the correlation data to be imaged
        currentCorr = meanCorrData.data.(components{i});
        
        % Get the thresholded correlation data to be imaged
        currentCutoffs =  meanCorrData.info.cutoffs.(components{i});
        currentThreshCorr = currentCorr;
        currentThreshCorr(currentThreshCorr >= currentCutoffs(1) & currentThreshCorr <= currentCutoffs(2)) = 0;
        
        % Produce images of raw average cross-correlation
        f_EEG_colormap(currentCorr(:, j), meanCorrData.info.channels, colorBoundsMean);
        currentTitleStr = sprintf('%s BLP-%s Average Cross-Correlation (%d s Time Shift)', bandStr, components{i}, -shiftsTime(j));
        title(currentTitleStr)
        
        % Save in the appropriate folder
        currentSaveName = sprintf('%04d', m);
        currentSaveStr = [saveDirsMean{i} '\' currentSaveName '.png'];
        saveas(gcf, currentSaveStr, 'png')
        close
        
        % Produce images of thresholded average cross-correlation
        f_EEG_colormap(currentThreshCorr(:, j), meanCorrData.info.channels, colorBoundsMean);
        currentTitleStr = sprintf('%s BLP-%s Thresholded Average Cross-Correlation (%d s Time Shift)', bandStr, components{i}, -shiftsTime(j));
        title(currentTitleStr)
        
        % Save in the appropriate older
        currentSaveName = sprintf('%04d', m);
            m = m + 1;
        currentSaveStr = [saveDirsThresh{i} '\' currentSaveName '.png'];
        saveas(gcf, currentSaveStr, 'png')
        close
    end
end

% Garbage collect
clear current* meanCorrData