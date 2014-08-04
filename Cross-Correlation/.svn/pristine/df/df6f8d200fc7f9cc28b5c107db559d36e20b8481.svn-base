function ai_corrGG(fileStruct, paramStruct)

%% Initialize
% Assign inputs
assignInputs(fileStruct.analysis.xcorr.Global_Global, 'createOnly')
assignInputs(paramStruct.xcorr.Global_Global, 'createOnly')

% Initialize the folder structure for saving images
masterSaveDir = [savePathImage '\' saveID];
if imageSingleSubjects
    firstLevel = {...
        'Mean Images', [];...
        'Subject', subjects};
    secondLevel = {'Scan', 'Subject', scans};
else
    firstLevel = {'Mean Images', []};
    secondLevel = [];
end
folderStruct = createNestedFolders(...
    'inPath', masterSaveDir,...
    'firstLevel', firstLevel,...
    'secondLevel', secondLevel);
    

%% Image the Raw Cross-Correlation Data
if imageSingleSubjects    
    % Load the raw cross-correlation data
    corrLoadStr = ['corrData_Global-Global_' saveID '.mat'];
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
            % Get the data to be imaged
            currentCorr = corrData(i, j).data;
            if ~isrow(currentCorr)
                currentCorr = currentCorr';
            end
            currentCorr = currentCorr(1, (shiftsTimeAll == imageShifts));
            
            figure;
            plot(imageShifts, currentCorr, 'b',...
                'LineWidth', 3)
            currentTitleStr = sprintf('Subject %d Scan %d Global-Global Signal Raw Cross-Correlation', i, j);
            title(currentTitleStr)
            xlabel('Time Shifts (s)')
            ylabel('Correlation Coefficient')
            currentSavePath = folderStruct.Subject.(num2word(i)).Scan.(num2word(j));
            currentSaveName = sprintf('%04d', 1);
            currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
            saveas(gcf, currentSaveStr, 'png')
            close
                
            progressbar([], j/length(scans{i}))
        end
        progressbar(find(subjects == i)/length(subjects), [])
    end

    % Garbage collect
    clear corrData current*
    
end


%% Image the Raw Mean & Thresholded Mean Cross-Correlation Data
% Load the mean cross-correlation data
meanLoadStr = ['meanCorrData_Global-Global_' saveID '.mat'];
load(meanLoadStr);

% Concatenate the correlation & thresholded correlation data
% Get the correlation data to be imaged
currentCorr = meanCorrData.mean(1, shiftsTimeAll == imageShifts);
currentStd = meanCorrData.std(1, shiftsTimeAll == imageShifts);
currentSE(1, :) = currentCorr + currentStd;
currentSE(2, :) = currentCorr - currentStd;

figure;
plot(imageShifts, currentCorr, 'b',...
    'LineWidth', 3)
hold on
plot(imageShifts, currentSE(1, :), 'g',...
    'LineWidth', 3)
plot(imageShifts, currentSE(2, :), 'g',...
    'LineWidth', 3)
currentTitleStr = sprintf('Global-Global Signal Average Cross-Correlation');
title(currentTitleStr)
xlabel('Time Shifts (s)')
ylabel('Correlation Coefficient')
currentSavePath = folderStruct.MeanImages.root;
currentSaveName = sprintf('1');
currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
saveas(gcf, currentSaveStr, 'png')
close

% Garbage collect
clear current* meanCorrData