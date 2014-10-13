%% 20140623 


%% 1601 - Running BOLD-EEG SWPC Analysis Using 20s Windows

% Today's parameters
load masterStructs;
timeStamp = '201406231601';
analysisStr = 'BOLD - EEG SWPC';
saveStr = '%s/%s-%i - BOLD-%s SWPC';
imSaveStr = '%s/%s-%i(%i) - BOLD-%s SWPC';

% Correlation parameters
channels = {'FPz', 'C3', 'PO8'};    % <--- Robust correlations at multiple time shifts
sigOffset = 4;                      % <--- Correlations strongest at ~4s
windowLength = 20;                  % <--- 20 seconds captures one oscillation at 0.05 Hz
szBOLD = [91 109 91 218]; 
controlDelay = 4;
overlap = windowLength-2;

% Imaging parameters
slicesToPlot = 48:4:64;
timesToPlot = 1:5:200;
titleStr = 'BOLD-%s SWPC (Subject %i, Scan %i)';

% Get the data set file paths
boldPath = [fileStruct.Paths.DataObjects '/BOLD/'];
boldStr = '_dcZ';
eegPath = [fileStruct.Paths.DataObjects '/EEG/'];
eegStr = '_dcZ';
boldFiles = get(fileData(boldPath, 'search', boldStr), 'Path');
eegFiles = get(fileData(eegPath, 'search', eegStr), 'Path');

% Convert time units to sample units
sigOffset = sigOffset * 0.5;
windowLength = windowLength * 0.5;
controlDelay = controlDelay * 0.5;
overlap = overlap * 0.5;

progbar = progress('Sliding Window Correlation', 'Scans Completed', 'Channels Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    
    corrDataCell = cell(1, length(channels));
    
    reset(progbar, 2);
    for b = 1:length(boldData)
        
        % Get & mask the functional data
        functionalData = ToMatrix(boldData(b));
        idsMask = isnan(functionalData(:, 1));
        functionalData(idsMask, :) = [];
        
        % Extract & regress control data from BOLD
        [controlData, nuisanceStrs] = ToArray(boldData(b), 'Nuisance');
        functionalData = Signal.regress(functionalData, controlData);
        
        % Remove delay from control data for regression from EEG
        controlData(strcmpi(nuisanceStrs, 'wm'), :) = [controlData(strcmpi(nuisanceStrs, 'wm'), controlDelay+1:end) zeros(1, controlDelay)];
        controlData(strcmpi(nuisanceStrs, 'global'), :) = [controlData(strcmpi(nuisanceStrs, 'global'), controlDelay+1:end) zeros(1, controlDelay)];
        
        % Get the EEG data & regress control data
        ephysData = ToArray(eegData(b), channels);
        ephysData = Signal.regress(ephysData, controlData);
        
        % Apply a time shift for the hemodynamic delay
        ephysData(:, end-sigOffset+1:end) = [];
        functionalData(:, 1:sigOffset) = [];
        
        % Crop out end time points that can't be used to construct a full length window into the time series
        extraTimePoints = mod(length(ephysData), windowLength);
        if extraTimePoints ~= 0
            functionalData(:, end - (extraTimePoints - 1):end) = [];
            ephysData(:, end - (extraTimePoints - 1):end) = [];
        end
        
        % Calculate sliding window correlation
        reset(progbar, 3);
        for c = 1:length(channels)
            tempCorr = zeros(size(functionalData, 1), (length(ephysData)-windowLength)/(windowLength - overlap));
            e = 1;
            for d = 1:(windowLength - overlap):length(ephysData)-windowLength
                tempCorr(:, e) = xcorrArr(functionalData(:, d:d+windowLength-1), ephysData(c, d:d+windowLength-1), 'MaxLag', 0);
                e = e + 1;
            end

            % Store the current correlation series
            currentCorr = nan(length(idsMask), size(tempCorr, 2));
            currentCorr(~idsMask, :) = tempCorr;
            currentCorr = reshape(currentCorr, [szBOLD(1:3) size(currentCorr, 2)]);
            corrDataCell{c} = cat(5, corrDataCell{c}, currentCorr);

            % Image the correlation data
            brainData = brainPlot('mri', currentCorr(:, :, slicesToPlot, timesToPlot),...
                'Title', sprintf(titleStr, channels{c}, a, b),...
                'XTickLabel', (timesToPlot)*2,...
                'XLabel', 'Time (s)',...
                'YTickLabel', slicesToPlot,...
                'YLabel', 'Slice Number');    

            set(brainData.Axes.Primary, 'FontSize', 12);
            set(get(brainData.Axes.Primary, 'XLabel'), 'FontSize', 16);
            set(get(brainData.Axes.Primary, 'YLabel'), 'FontSize', 16);

            % Save the image & close
            imageSaveStr = sprintf(imSaveStr, fileStruct.Paths.TodayData, timeStamp, a, b, channels{c});
            saveas(brainData.FigureHandle, [imageSaveStr '.png'], 'png');
            close(brainData);
            
            update(progbar, 3, c/length(channels));
        end

        update(progbar, 2, b/length(boldData));
    end
    
    % Save the correlation data
    for b = 1:length(channels)
        corrData = corrDataCell{b};
        dataSaveStr = sprintf(saveStr, fileStruct.Paths.TodayData, timeStamp, a, channels{b});
        save([dataSaveStr '.mat'], 'corrData', '-v7.3');
    end

    update(progbar, 1, a/length(boldFiles));
end
close(progbar);



%% 1849 - 

load masterStructs;
% 
% load eegObject-1_RS_dcZ_20130906;
% load boldObject-1_RS_dcZ_20131030;

funData = ToMatrix(boldData(1));
idsFunNaN = isnan(funData(:, 1));
funData(idsFunNaN, :) = [];


ephysData = eegData(1).Data.EEG;
idsNaN = isnan(ephysData(:, 1));
ephysData(idsNaN, :) = [];

icData = fastica(ephysData, 'numOfIC', 25);

for a = 1:size(icData, 1)
    
    corrData = xcorrArr(funData, icData(a, :), 'MaxLag', 10);
    
    corrDataPlot = nan(length(idsFunNaN), 21);
    corrDataPlot(~idsFunNaN, :) = corrData;
    corrDataPlot = reshape(corrDataPlot, [91 109 91 21]);
    
    brainData = brainPlot('mri', corrDataPlot(:, :, 48:4:64, :),...
        'ColorbarLabel', 'r',...
        'Title', 'BOLD-EEG IC Cross Correlation',...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', -20:2:20,...
        'YLabel', 'Slice Number',...
        'YTickLabel', 48:4:64);
end

    


