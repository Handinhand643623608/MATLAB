function ai_powerSpectra_EEG(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.powerSpectra.EEG, 'createOnly');
assignInputs(paramStruct.powerSpectra.EEG, 'createOnly');
propBandStr = paramStruct.powerSpectra.(bandStr).propBandStr;

% Load data stored elsewhere
loadStr = ['spectralData_' electrodes{1} electrodes{2} '_' saveTag '_' saveID '.mat'];
load(loadStr)

% Initialize the folder structure for saved images
masterSaveDir = [savePathImage '\' saveID];
for i = 1:length(electrodes)
    inPath = [masterSaveDir '\' electrodes{i}];
    firstLevel = {'Mean Images', []; 'Subject', subjects};
    secondLevel = {'Scan', 'Subject', scans};
    folderStruct.(electrodes{i}) = createNestedFolders(...
        'inPath', inPath,...
        'firstLevel', firstLevel,...
        'secondLevel', secondLevel);
end


%% Image the Spectral Data
m = 1;
progressbar('Spectral Images Created', 'Subjects Completed', 'Scans Completed')
for i = 1:length(electrodes)
    for j = subjects
        for k = scans{i}
            % Get the current spectral data to be imaged
            currentSpectrum = spectralData(j, k).data.(electrodes{i});
            
            % Plot the spectral data
            figure('Visible', visibleFigs);
            plot(currentSpectrum)
            titleStr = sprintf('Subject %d Scan %d %s Welch Spectrum', j, k, electrodes{i});
            title(titleStr)
            xlabel('Frequency (Hz)')
            ylabel('Power (dB/Hz)')
            currentSavePath = folderStruct.(electrodes{i}).Subject.(num2word(j)).Scan.(num2word(k));
            currentSaveName = sprintf('%03d', m);
            currentSaveStr = [currentSavePath '\' currentSaveName '.png'];
                m = m + 1;
            saveas(gcf, currentSaveStr, 'png')
            close
        end
    end
end