function ai_corrGB(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.globSig_BOLD, 'createOnly');
assignInputs(paramStruct.xcorr.globSig_BOLD, 'createOnly');

% Load the anatomical images
mniBrain = load_nii(fileStruct.files.MNI);
mniBrain = mniBrain.img;

% Initialize the folder structure for saving images
masterSaveDir = [savePathImage '\' saveID];
firstLevel = {'Mean Image', []; 'Mean Thresholded Image', []; 'Subject', subjects};
secondLevel = {'Scan', 'Subject', scans};
folderStruct = createNestedFolders('inPath', masterSaveDir, 'firstLevel', firstLevel, 'secondLevel', secondLevel);

% Initialize parallel processing
% if parallelSwitch && matlabpool('size') == 0
%     matlabpool
% elseif ~parallelSwitch && matlabpool('size') ~= 0
%     matlabpool close
% end


%% Image the Single Subject Global Signal-BOLD Correlations
if imageSingleSubjects
    % Load the raw cross-correlation data
    corrLoadStr = ['corrData_globSigEEG-BOLD_' saveID '.mat'];
    load(corrLoadStr)
    
    % Check to see if specific time shifts are to be imaged
    if ~exist('shiftsToImage', 'var')
        shiftsToImage = corrData(1, 1).info.shiftsTime;
    end
    shiftsTimeAll = corrData(1, 1).info.shiftsTime;
    
    progressbar('Correlation Images Generated', 'Scans Completed')
    m = 1;
    for i = subjects
        progressbar([], 0)
        for j = scans{i}
            % Get the current data to be imaged
            currentCorr = corrData(i, j).data;
            
            % Cut down the data to the slices of interest
            currentCorr = currentCorr(:, :, slicesToImage, :);
            
            % Rotate & flip the data for proper display orientation
            currentCorr = permute(currentCorr, [2 1 3 4]);
            currentCorr = flipdim(currentCorr, 1);
            
            % Get the tick sizes for relabeling image axes
            xTickSize = size(currentCorr, 2);
            yTickSize = size(currentCorr, 1);
            
            % Convert data from 3D to 2D
            currentCorr = combine_4Dto3D(currentCorr, length(slicesToImage));
            
            % Calulate tick locations
            yTickLocations = (yTickSize/2):yTickSize:((yTickSize/2) + (yTickSize*(size(currentCorr, 3) - 1)));
            xTickLocations = (xTickSize/2):xTickSize:((xTickSize/2) + (size(currentCorr, 2) - (xTickSize/2)));
            
            % Convert 3D data to 2D
            currentCorr = currentCorr(:, :, shiftsToImage);
            currentCorr = combine_3Dto2D(currentCorr, 1);
            
            % Remove 0s in data to help visualization
            currentCorr(currentCorr == 0) = NaN;
            
            % Make the images
            figure('Visible', visibleFigs);
            imagesc(currentCorr);
            axis equal
            label_image_axes(slicesToImage, 'bottom', gcf, xTickLocations);
            label_image_axes(-shiftsTimeAll(shiftsToImage), 'left', gcf, yTickLocations);
            ylabel('Time Shift (Seconds)')
            xlabel('Slice')
            title(['Global-BOLD Cross-Correlation (Subject ' num2str(i) ' Scan ' num2str(j) ')']);
            colorbar
            currentSavePath = folderStruct.Subject.(num2word(i)).Scan.(num2word(j));
            currentSaveName = sprintf('%03d', m);
            currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
            saveas(gcf, currentSaveStr, 'png')
                m = m + 1;
            close
            
            progressbar([], j/length(scans{i}))
        end
        progressbar(find(subjects == i)/length(subjects), [])
    end
end

% Garbage collect
clear current* corrData


%%  Image the Average & Thresholded Cross-Correlation Data
% Load the mean cross-correlation data
meanLoadStr = ['meanCorrData_globSigEEG-BOLD_' saveID '.mat'];
load(meanLoadStr)

% Get the mean correlation data
currentMeanCorr = meanCorrData.data;
currentCutoffs = meanCorrData.info.cutoffs;
currentMeanCorr = currentMeanCorr(:, :, slicesToImage, ismember(shiftsTime, shiftsToImage));
anatomicalImage = mniBrain(:, :, slicesToImage);

% Montage the data
u_dataMontage(currentMeanCorr,...
    'axesColor', 'w',...
    'backgroundColor', 'k',...
    'colorBounds', [-25 25],...
    'colorMap', jet(256),...
    'dataType', 'MRI',...
    'figurePosition', 'right-center',...    
    'figureSize', 'fullScreen',...    
    'fontColor', 'w',...
    'fontWeight', 'bold',...
    'NaNColor', [0 0 0],...
    'plotTitle', 'EEG Global Signal-BOLD Average Correlations',...    
    'spacing', 0,...
    'visibleCBar', 'on',...
    'visibleFigs', 'on',...
    'xTitle', 'Slices',...
    'xTickLabels', slicesToImage,...
    'yTitle', 'Time Shifts (s)',...
    'yTickLabels', shiftsToImage);

% Fix colorbar & save image
cbarHandle = findobj(gcf, 'Tag', 'Colorbar');
set(cbarHandle, 'YTick', -0.2:0.4:0.2);
set(gcf, 'InvertHardcopy', 'off', 'Renderer', 'painters', 'Units', 'inches');
currentPosition = get(gcf, 'Position');
currentPosition(1:2) = 0;
set(gcf,...
    'PaperSize', currentPosition(3:4),...
    'PaperPosition', currentPosition);
saveas(gcf, [masterSaveDir '\(DC EEG GR)-BOLD Montage.pdf'], 'pdf');
saveas(gcf, [masterSaveDir '\(DC EEG GR)-BOLD Montage.eps'], 'eps');

    % Montage the data
u_dataMontage(currentMeanCorr,...
    'axesColor', 'w',...
    'backgroundColor', 'k',...
    'colorBounds', [-25 25],...
    'colorMap', jet(256),...
    'dataType', 'MRI',...
    'figurePosition', 'right-center',...    
    'figureSize', 'fullScreen',...    
    'fontColor', 'w',...
    'fontWeight', 'bold',...
    'anatomicalImage', anatomicalImage,...
    'maskThresholds', currentCutoffs,...
    'NaNColor', [0 0 0],...
    'plotTitle', 'EEG Global Signal-BOLD Thresholded Average Correlations',...    
    'spacing', 0,...
    'visibleCBar', 'on',...
    'visibleFigs', 'on',...
    'xTitle', 'Slices',...
    'xTickLabels', slicesToImage,...
    'yTitle', 'Time Shifts (s)',...
    'yTickLabels', shiftsToImage);

        % Fix colorbar & save image
cbarHandle = findobj(gcf, 'Tag', 'Colorbar');
set(cbarHandle, 'YTick', -0.2:0.4:0.2);
set(gcf, 'InvertHardcopy', 'off', 'Renderer', 'painters', 'Units', 'inches');
currentPosition = get(gcf, 'Position');
currentPosition(1:2) = 0;
set(gcf,...
    'PaperSize', currentPosition(3:4),...
    'PaperPosition', currentPosition);
saveas(gcf, [masterSaveDir '\(DC EEG GR)-BOLD Thresholded Montage.pdf'], 'pdf');
saveas(gcf, [masterSaveDir '\(DC EEG GR)-BOLD Thresholded Montage.eps'], 'eps');