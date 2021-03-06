function ai_corrEEG(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific variables
assignInputs(paramStruct.globalRegression.EEG, 'createOnly')
assignInputs(fileStruct.analysis.globalRegression.EEG, 'createOnly')

% Initialize the file structure for saving images
masterSaveDir = [savePathImage '\' saveID];
masterSaveDir = checkExisting(masterSaveDir, 'fileExt', 'dir');
mkdir(masterSaveDir);
if ~averageFlag
    nameFirstLevel = {'Subject', subjects};
    nameSecondLevel = {'Scan/Subject', scans};
    saveStruct = createNestedFolders('inPath', masterSaveDir, 'nameFirstLevel', nameFirstLevel,...
        'nameSecondLevel', nameSecondLevel);
end

%% Image the Non-Regressed EEG Correlation Data
load(eegDataFile);

m = 1;
tempCorr = [];
for i = subjects
    for j = scans{i}
        % Get the current data to be imaged
        currentEEG = eegData(i, j).data.EEG;
        currentChannels = eegData(i, j).info.channels;        
        
        % Image the DC correlation data for each subject & scan (if applicable)
        if ~averageFlag
            % Create correlation maps
            [currentCorr currentOrder] = correlation_map(currentEEG);
        
            % Put the EEG channel list in the proper order
            currentOrdChan = currentChannels(currentOrder);
            
            figure('Visible', visibleFigs)
            imagesc(currentCorr, [-1 1]);
            colorbar;
            currentTitleStr = sprintf('DC EEG Clustering for Subject %d Scan %d', i, j);
            title(currentTitleStr)
            labelFigure(...
                'xLabels', currentOrdChan,...
                'yLabels', currentOrdChan,...
                'xRotation', 90,...
                'xFontSize', 6,...
                'yFontSize', 6,...
                'imageFlag', 1,...
                'tickDir', 'off');
            currentSaveName = sprintf('%03d', m);
                m = m + 1;
            currentSaveDir = saveStruct.Subject.(num2word(i)).Scan.(num2word(j));
            currentSaveFig = [currentSaveDir '\' currentSaveName '.fig'];
            currentSavePNG = [currentSaveDir '\' currentSaveName '.png'];
            saveas(gcf, currentSaveFig, 'fig')
            saveas(gcf, currentSavePNG, 'png')
            close
        else
            % Calculate all correlations first
            currentEEG = u_standardize_EEG(currentEEG, currentChannels, paramStruct);
            currentEEG = currentEEG';
            currentCorr = corrcoef(currentEEG);
            
            % Store the correlation matrices
            tempCorr = cat(3, tempCorr, currentCorr);            
        end
    end
    
    % Garbage collect
    clear current*
end

% Image the averaged & sorted data
if averageFlag
    currentMeanCorr = nanmean(tempCorr, 3);
    currentChannels = paramStruct.general.channels;
    currentNumChannels = length(currentChannels);
    
    % Sort the data
    currentNumGreater = zeros(currentNumChannels, 1);
    for i = 1:currentNumChannels
        [NU idsSorted] = sort(currentMeanCorr(:, i), 'ascend');
        currentSortedCorr = currentMeanCorr(idsSorted, idsSorted);
        currentCheck = currentSortedCorr(2:end, 2:end) > currentSortedCorr(1:end-1, 1:end-1);
        currentNumGreater(i) = sum(currentCheck(:));
    end
    
    % Use the best sorted data set
    [NU idsSorted] = sort(currentMeanCorr(:, currentNumGreater == max(currentNumGreater)), 'ascend');
    currentSortedCorr = currentMeanCorr(idsSorted, idsSorted);
    currentSortedChannels = currentChannels(idsSorted);
    
    % Image the data
    figure('Visible', visibleFigs)
    imagesc(currentSortedCorr, [-1 1]);
    colorbar;
    title('Sorted Average DC EEG Clustering')
    labelFigure(...
        'xLabels', currentSortedChannels,...
        'yLabels', currentSortedChannels,...
        'xRotation', 90,...
        'xFontSize', 6,...
        'yFontSize', 6,...
        'imageFlag', 1,...
        'tickDir', 'off');
    currentSaveName = sprintf('%03d', m);
        m = m + 1;
    currentSaveFig = [masterSaveDir '\' currentSaveName '.fig'];
    currentSavePNG = [masterSaveDir '\' currentSaveName '.png'];
    saveas(gcf, currentSaveFig, 'fig')
    saveas(gcf, currentSavePNG, 'png')
    close
    
    % Find & store the 5 most anticorrelated electrode pairings
    aCorrChannels = cell(30, 2);
    tempSortedCorr = triu(currentSortedCorr);
    tempSortedCorr = tempSortedCorr(:);
    for i = 1:30        
        maxACorr = min(tempSortedCorr);        
        [idxChannel(i, 1) idxChannel(i, 2)] = find(currentSortedCorr == maxACorr, 1);
        aCorrChannels{i, 1} = currentSortedChannels{idxChannel(i, 1)};
        aCorrChannels{i, 2} = currentSortedChannels{idxChannel(i, 2)};
        tempSortedCorr(tempSortedCorr == min(tempSortedCorr)) = [];
    end
    
    eegData(1, 1).info.aCorrChannels = aCorrChannels;
    save(eegDataFile, 'eegData', '-v7.3')
end

% Clear out the data set
clear eegData current* temp*

    
%% Image the Global Regressed EEG Data
loadStr = [savePathData '\eegData_' saveTag '_' saveID '.mat'];
load(loadStr);    

tempCorr = [];
for i = subjects
    for j = scans{i}
        % Get the current data to be imaged
        currentEEG = eegData(i, j).data.EEG;
        currentChannels = eegData(i, j).info.channels;        
        
        % Image the DC GR correlation data for each subject & scan (if applicable)
        if ~averageFlag
            % Create correlation maps
            [currentCorr currentOrder] = correlation_map(currentEEG);
        
            % Put the EEG channel list in the proper order
            currentOrdChan = currentChannels(currentOrder);
            
            figure('Visible', visibleFigs)
            imagesc(currentCorr, [-1 1]);
            colorbar;
            currentTitleStr = sprintf('DC GR EEG Clustering for Subject %d Scan %d', i, j);
            title(currentTitleStr)
            labelFigure(...
                'xLabels', currentOrdChan,...
                'yLabels', currentOrdChan,...
                'xRotation', 90,...
                'xFontSize', 6,...
                'yFontSize', 6,...
                'imageFlag', 1,...
                'tickDir', 'off');
            currentSaveName = sprintf('%03d', m);
                m = m + 1;
            currentSaveDir = saveStruct.Subject.(num2word(i)).Scan.(num2word(j));
            currentSaveFig = [currentSaveDir '\' currentSaveName '.fig'];
            currentSavePNG = [currentSaveDir '\' currentSaveName '.png'];
            saveas(gcf, currentSaveFig, 'fig')
            saveas(gcf, currentSavePNG, 'png')
            close
        else
            % Calculate all correlations first
            currentEEG = u_standardize_EEG(currentEEG, currentChannels, paramStruct);
            currentEEG = currentEEG';
            currentCorr = corrcoef(currentEEG);
            
            % Store the correlation matrices
            tempCorr = cat(3, tempCorr, currentCorr);            
        end
    end
    
    % Garbage collect
    clear current*
end

% Image the averaged & sorted data
if averageFlag
    currentMeanCorr = nanmean(tempCorr, 3);
    currentChannels = paramStruct.general.channels;
    currentNumChannels = length(currentChannels);
    
    % Sort the data
    currentNumGreater = zeros(currentNumChannels, 1);
    for i = 1:currentNumChannels
        [NU idsSorted] = sort(currentMeanCorr(:, i), 'ascend');
        currentSortedCorr = currentMeanCorr(idsSorted, idsSorted);
        currentCheck = currentSortedCorr(2:end, 2:end) > currentSortedCorr(1:end-1, 1:end-1);
        currentNumGreater(i) = sum(currentCheck(:));
    end
    
    % Use the best sorted data set
    [NU idsSorted] = sort(currentMeanCorr(:, currentNumGreater == max(currentNumGreater)), 'ascend');
    currentSortedCorr = currentMeanCorr(idsSorted, idsSorted);
    currentSortedChannels = currentChannels(idsSorted);
    
    % Image the data
    figure('Visible', visibleFigs);
    imagesc(currentSortedCorr, [-1 1]);
    colorbar;
    title('Sorted Average DC GR EEG Clustering')
    labelFigure(...
        'xLabels', currentSortedChannels,...
        'yLabels', currentSortedChannels,...
        'xRotation', 90,...
        'xFontSize', 6,...
        'yFontSize', 6,...
        'imageFlag', 1,...
        'tickDir', 'off');
    currentSaveName = sprintf('%03d', m);
        m = m + 1;
    currentSaveFig = [masterSaveDir '\' currentSaveName '.fig'];
    currentSavePNG = [masterSaveDir '\' currentSaveName '.png'];
    saveas(gcf, currentSaveFig, 'fig')
    saveas(gcf, currentSavePNG, 'png')
    close
    
    % Find & store the 5 most anticorrelated electrode pairings
    aCorrChannels = cell(30, 2);
    tempSortedCorr = triu(currentSortedCorr);
    tempSortedCorr = tempSortedCorr(:);
    for i = 1:30        
        maxACorr = min(tempSortedCorr);        
        [idxChannel(i, 1) idxChannel(i, 2)] = find(currentSortedCorr == maxACorr, 1);
        aCorrChannels{i, 1} = currentSortedChannels{idxChannel(i, 1)};
        aCorrChannels{i, 2} = currentSortedChannels{idxChannel(i, 2)};
        tempSortedCorr(tempSortedCorr == min(tempSortedCorr)) = [];
    end
    
    eegData(1, 1).info.aCorrResults = aCorrChannels;
    save(loadStr, 'eegData', '-v7.3');
end
            