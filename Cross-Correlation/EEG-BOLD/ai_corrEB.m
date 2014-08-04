function ai_corrEB(fileStruct, paramStruct)

%% Initialize
% Load standard anatomical images
mniBrain = load_nii(fileStruct.files.MNI);
mniBrain = mniBrain.img;

% Initialize function-specific parameters
assignInputs(fileStruct.analysis.xcorr.EEG_BOLD, 'createOnly')
assignInputs(paramStruct.xcorr.EEG_BOLD, 'createOnly')

% Initialize the folder structure for saving outputs
masterSaveDir = [savePathImage '\' saveID];
for i = 1:length(electrodes)
    inPath = [masterSaveDir '\' electrodes{i}];
    firstLevel = {'Mean Images', []; 'Mean Thresholded Images', []; 'Subject', subjects};
    secondLevel = {'Scan', 'Subject', scans};
    folderStruct.(electrodes{i}) = createNestedFolders(...
        'inPath', inPath,...
        'firstLevel', firstLevel,...
        'secondLevel', secondLevel);
end
  

%% Image the Raw Cross-Correlation Data
% Load the raw cross-correlation data
loadStr = ['corrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
load(loadStr)

% Initialize index for counting images
m = 1;

if imageSingleSubjects
    for i = subjects            
        for j = scans{i}
            for k = 1:length(electrodes)            
                % Get the data to be imaged
                current_xcorr = corrData(i, j).data.(electrodes{k});

                % Cut the data down to slices of interest
                current_xcorr = current_xcorr(:, :, imageSlices, :);

                % Rotate & flip the data for proper display orientation
                current_xcorr = permute(current_xcorr, [2 1 3 4]);
                current_xcorr = flipdim(current_xcorr, 1);

                % Get the tick sizes for relabeling image axes
                x_tick_size = size(current_xcorr, 2);
                y_tick_size = size(current_xcorr, 1);

                % Convert data from 3D to 2D
                current_xcorr = combine_4Dto3D(current_xcorr, length(imageSlices));

                % Calculate tick locations
                y_tick_locations = (y_tick_size/2):y_tick_size:((y_tick_size/2) + (y_tick_size*(size(current_xcorr, 3) - 1)));
                x_tick_locations = (x_tick_size/2):x_tick_size:((x_tick_size/2) + (size(current_xcorr, 2) - (x_tick_size/2)));

                % Convert 3D data to 2D
                current_xcorr = current_xcorr(:, :, imageShifts);
                current_xcorr = combine_3Dto2D(current_xcorr, 1);

                % Remove 0s in the data to help visualization
                current_xcorr(current_xcorr == 0) = NaN;

                % Make the images
                figure('Visible', visibleFigs);
                imagesc(current_xcorr, [-1 1]);
                axis equal
                label_image_axes(imageSlices, 'bottom', gcf, x_tick_locations);
                label_image_axes(-shiftsTime(imageShifts), 'left', gcf, y_tick_locations);
                ylabel('Time Shift (Seconds)')
                xlabel('Slice')
                title([electrodes{k} '-BOLD Cross-Correlation (Subject ' num2str(i) ' Scan ' num2str(j) ')']);
                colorbar
                currentSavePath = folderStruct.(electrodes{k}).Subject.(num2word(i)).Scan.(num2word(j));
                currentSaveName = sprintf('%03d', m);
                currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
                    m = m + 1;
                saveas(gcf, currentSaveStr, 'png')
                close
            end
        end
    end
end

% Garbage collect
clear current* corrData

%% Image the Average Cross-Correlations Data
% Load the mean cross-correlation data
loadStr = ['meanCorrData_' saveTag '_' electrodes{1} electrodes{2} '-BOLD_' saveID '.mat'];
load(loadStr)

for i = 1:length(electrodes)
    % Get the data to be imaged
    currentMeanCorr = meanCorrData.data.(electrodes{i});
    currentMeanCorr = currentMeanCorr(:, :, imageSlices, ismember(shiftsTime, imageShifts));
    anatomicalImage = mniBrain(:, :, imageSlices);
    currentCutoffs = meanCorrData.info.cutoffs.(electrodes{i});
    
    % Montage the data
    u_dataMontage(currentMeanCorr,...
        'axesColor', 'w',...
        'backgroundColor', 'k',...
        'colorBounds', [-0.2 0.2],...
        'colorMap', jet(256),...
        'dataType', 'MRI',...
        'figurePosition', 'right-center',...    
        'figureSize', 'fullScreen',...    
        'fontColor', 'w',...
        'fontWeight', 'bold',...
        'NaNColor', [0 0 0],...
        'plotTitle', [electrodes{i} '-BOLD Average Correlations'],...    
        'spacing', 0,...
        'visibleCBar', 'on',...
        'visibleFigs', 'on',...
        'xTitle', 'Slices',...
        'xTickLabels', imageSlices,...
        'yTitle', 'Time Shifts (s)',...
        'yTickLabels', imageShifts);
    
    % Fix colorbar & save image
    cbarHandle = findobj(gcf, 'Tag', 'Colorbar');
    set(cbarHandle, 'YTick', -0.2:0.4:0.2);
    set(gcf, 'InvertHardcopy', 'off', 'Renderer', 'painters', 'Units', 'inches');
    currentPosition = get(gcf, 'Position');
    currentPosition(1:2) = 0;
    set(gcf,...
        'PaperSize', currentPosition(3:4),...
        'PaperPosition', currentPosition);
    saveas(gcf, [masterSaveDir '\' electrodes{i} '-BOLD Montage.pdf'], 'pdf');
    saveas(gcf, [masterSaveDir '\' electrodes{i} '-BOLD Montage.eps'], 'eps');
    
        % Montage the data
    u_dataMontage(currentMeanCorr,...
        'axesColor', 'w',...
        'backgroundColor', 'k',...
        'colorBounds', [-0.2 0.2],...
        'colorMap', jet(256),...
        'dataType', 'MRI',...
        'figurePosition', 'right-center',...    
        'figureSize', 'fullScreen',...    
        'fontColor', 'w',...
        'fontWeight', 'bold',...
        'anatomicalImage', anatomicalImage,...
        'maskThresholds', currentCutoffs,...
        'NaNColor', [0 0 0],...
        'plotTitle', [electrodes{i} '-BOLD Thresholded Average Correlations'],...    
        'spacing', 0,...
        'visibleCBar', 'on',...
        'visibleFigs', 'on',...
        'xTitle', 'Slices',...
        'xTickLabels', imageSlices,...
        'yTitle', 'Time Shifts (s)',...
        'yTickLabels', imageShifts);

            % Fix colorbar & save image
    cbarHandle = findobj(gcf, 'Tag', 'Colorbar');
    set(cbarHandle, 'YTick', -0.2:0.4:0.2);
    set(gcf, 'InvertHardcopy', 'off', 'Renderer', 'painters', 'Units', 'inches');
    currentPosition = get(gcf, 'Position');
    currentPosition(1:2) = 0;
    set(gcf,...
        'PaperSize', currentPosition(3:4),...
        'PaperPosition', currentPosition);
    saveas(gcf, [masterSaveDir '\' electrodes{i} '-BOLD Thresholded Montage.pdf'], 'pdf');
    saveas(gcf, [masterSaveDir '\' electrodes{i} '-BOLD Thresholded Montage.eps'], 'eps');
end
