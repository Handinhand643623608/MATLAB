function ar_powerSpectra_EEG(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
assignInputs(fileStruct.analysis.powerSpectra.EEG, 'createOnly');
assignInputs(paramStruct.powerSpectra.EEG, 'createOnly');
electrodes = electrodes;

% Load data stored elsewhere
load(eegDataFile)
Fs = eegData(1, 1).info.Fs;

% Initialize the output structure
spectralData(size(eegData, 1), size(eegData, 2)) = struct('data', [], 'info', []);

% MATLAB parallel processing
if parallelSwitch && matlabpool('size') == 0
    matlabpool
elseif ~parallelSwitch && matlabpool('size') ~= 0
    matlabpool close
end

%% Create the EEG Spectra
progressbar('EEG Power Spectra Generation', 'Scans Finished')
for i = subjects
    progressbar([], 0)    
    for j = scans{i}        
        switch parallelSwitch
            case true
                parfor k = 1:length(electrodes)
                    % Get the EEG data to be analyzed
                    currentChannels = eegData(i, j).info.channels;
                    currentEEG = eegData(i, j).data.EEG(strcmp(electrodes{k}, currentChannels), :);

                    % Condition the data
                    currentEEG(isnan(currentEEG)) = 0;
                    currentEEG = double(currentEEG);

                    % Create the spectrum object
                    hs = spectrum.welch;
                    hs.SegmentLength = lengthSegment;
                    hs.OverlapPercent = pctOverlap;

                    % Create the spectral data
                    currentSpectrum{k} = hs.psd(...
                        currentEEG,...
                        'Fs', Fs,...
                        'FreqPoints', 'User Defined',...
                        'FrequencyVector', rangeFreqs,...
                        'SpectrumType', 'TwoSided');

                end

                for k = 1:length(electrodes)
                    % Fill in values in the data structure
                    spectralData(i, j).info = struct(...
                        'electrodes', {electrodes},...
                        'freqs', currentSpectrum.Frequencies,...
                        'Fs', Fs,...
                        'lengthSegement', lengthSegment,...
                        'pctOverlap', pctOverlap,...
                        'spectrumType', 'Two-Sided Welch',...
                        'comments', comments);
                    spectralData(i, j).data.(electrodes{k}) = currentSpectrum{k};
                end
                
            case false
                for k = 1:length(electrodes)
                    % Get the EEG data to be analyzed
                    currentChannels = eegData(i, j).info.channels;
                    currentEEG = eegData(i, j).data.EEG(strcmp(electrodes{k}, currentChannels), :);

                    % Condition the data
                    currentEEG(isnan(currentEEG)) = 0;
                    currentEEG = double(currentEEG);

                    % Create the spectrum object
                    hs = spectrum.welch;
                    hs.SegmentLength = lengthSegment;
                    hs.OverlapPercent = pctOverlap;

                    % Create the spectral data
                    currentSpectrum = hs.psd(...
                        currentEEG,...
                        'Fs', Fs,...
                        'FreqPoints', 'User Defined',...
                        'FrequencyVector', rangeFreqs,...
                        'SpectrumType', 'TwoSided');
                    
                    % Fill in values in the data structure
                    spectralData(i, j).info = struct(...
                        'electrodes', {electrodes},...
                        'freqs', currentSpectrum.Frequencies,...
                        'Fs', Fs,...
                        'lengthSegement', lengthSegment,...
                        'pctOverlap', pctOverlap,...
                        'spectrumType', 'Two-Sided Welch',...
                        'comments', comments);
                    spectralData(i, j).data.(electrodes{k}) = currentSpectrum{k};
                end                   
        end
        progressbar([], j/length(scans{i}))
    end
    progressbar(i/length(subjects), [])
end

% Save the spectral data
saveStr = [savePathData '\spectralData_' electrodes{1} electrodes{2} '_' saveTag '_' saveID '.mat'];
save(saveStr, 'spectralData', '-v7.3')

% Garbage collect
clear spectralData eegData current*
