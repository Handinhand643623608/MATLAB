%% 20140205


%% 0100 - Image the Thresholded Coherence Data from 20140203
load masterStructs
cohFiles = get(fileData([fileStruct.Paths.DataObjects '/Partial Coherence'], 'Search', 'meanPartial.*fb_.*_GSControl'), 'Path');

imageSavePath = [fileStruct.Paths.Desktop '/Partial Coherence'];
if ~exist(imageSavePath, 'dir'); mkdir(imageSavePath); end;

for a = 1:length(cohFiles)
    load(cohFiles{a})
    
    channel = fieldnames(meanCohData.Data);
    freqs = meanCohData.Parameters.Coherence.Frequencies;
    thresh = meanCohData.Parameters.SignificanceCutoffs.(channel{1});
    
    shadePlot(...
        freqs,...
        meanCohData.Data.(channel{1}).Mean,...
        meanCohData.Data.(channel{1}).SEM,...
        '-k',...
        'Color', 'w');
    hold on
    
    plot(freqs, ones(length(freqs))*thresh, '--r', 'LineWidth', 4);
        
    xlabel('Frequency (Hz)', 'FontSize', 14);
    ylabel('Magnitude Squared Coherence', 'FontSize', 14);
    title(['BOLD-' channel{1} ' Coherence'], 'FontSize', 16);
    
    saveas(gcf, [imageSavePath '/' channel{1} '.png'], 'png');
    saveas(gcf, [imageSavePath '/' channel{1} '.fig'], 'fig');
    close
end


%% 0140 - Make New EEG Power Spectra
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'fbZ'), 'Path');
channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};

% Setup the window length parameter (need to capture 0.01 Hz waves)
windowLength = 30000;

specStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', 'fb',...
        'GSR', false,...
        'ParentData', {eegFiles},...
        'Scans', [],...
        'ScanState', 'RS',...
        'Subjects', []),...
    'Spectrum', struct(...
        'Channels', [],...
        'FrequencyRange', 'onesided',...
        'NFFT', 256,...
        'SegmentOverlap', 0.5*windowLength,...
        'SpectrumType', 'psd',...
        'Window', hamming(windowLength)));
    
 progBar = progress('Computing EEG Power Spectra');
 for a = 1:length(channels)
     specStruct.Spectrum.Channels = channels(a);
     spectralData = spectralObj(specStruct);
     store(spectralData);
     meanSpectralData = mean(spectralData);
     store(meanSpectralData);
     clear spectralData meanSpectralData
     update(progBar, a/length(channels));
 end
 
 
 %% 0839 - Filtering EEG Data Before Spectrum Generation (0.01 - 0.5 Hz)
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'fbZ'), 'Path');

for a = 1:length(eegFiles)
    load(eegFiles{a})
    filter(eegData, 'Passband', [0.01 0.5]);
    zscore(eegData);
    store(eegData);
    clear eegData;
end


%% 0859 - Make EEG Power Spectra from Newly Filtered Data
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'wbdcZ'), 'Path');
channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};

% Setup the window length parameter (need to capture 0.01 Hz waves)
windowLength = 30000;

specStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', [0.01 0.5],...
        'GSR', false,...
        'ParentData', {eegFiles},...
        'Scans', [],...
        'ScanState', 'RS',...
        'Subjects', []),...
    'Spectrum', struct(...
        'Channels', [],...
        'FrequencyRange', 'onesided',...
        'NFFT', 256,...
        'SegmentOverlap', 0.5*windowLength,...
        'SpectrumType', 'psd',...
        'Window', hamming(windowLength)));
    
 progBar = progress('Computing EEG Power Spectra');
 for a = 1:length(channels)
     specStruct.Spectrum.Channels = channels(a);
     spectralData = spectralObj(specStruct);
     store(spectralData);
     meanSpectralData = mean(spectralData);
     store(meanSpectralData);
     clear spectralData meanSpectralData
     update(progBar, a/length(channels));
 end
 close(progBar);
 
 
 %% 0911 - Plot the New Spectra
 load masterStructs
 specFiles = get(fileData([fileStruct.Paths.DataObjects '/Spectra'], 'Search', 'mean.*wbdc'), 'Path');
 imagePath = [fileStruct.Paths.Desktop '/EEG Power Spectra'];
 if ~exist(imagePath, 'dir'); mkdir(imagePath); end;
 
 for a = 1:length(specFiles)
     load(specFiles{a})
     specWindow = plot(meanSpectralData);
     saveName = [imagePath '/' meanSpectralData.Channels{1}];
     saveas(specWindow.FigureHandle, [saveName '.png'], 'png');
     saveas(specWindow.FigureHandle, [saveName '.fig'], 'fig');
     close(specWindow);
     clear meanSpectralData;
 end
 
 
 %% 0921 - Forgot to Resample EEG Data
 % Need to downsample the EEG data so that the spectrum frequency range is lower
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'wbdcZ'), 'Path');

for a = 1:length(eegFiles)
    load(eegFiles{a})
    resample(eegData, 'Fs', 1);
    store(eegData)
end


%% 0942 - Make Power Spectra from the Downsampled EEG (50% Overlap)
load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'wbdcZ'), 'Path');
channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};
imagePath = [fileStruct.Paths.Desktop '/EEG Power Spectra'];
 if ~exist(imagePath, 'dir'); mkdir(imagePath); end;

% Setup the window length parameter (need to capture 0.01 Hz waves)
load(eegFiles{1});
fs = eegData(1).Fs;
windowLength = (1/0.01)*fs;

specStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', [0.01 0.5],...
        'GSR', false,...
        'ParentData', {eegFiles},...
        'Scans', [],...
        'ScanState', 'RS',...
        'Subjects', []),...
    'Spectrum', struct(...
        'Channels', [],...
        'FrequencyRange', 'onesided',...
        'NFFT', 256,...
        'SegmentOverlap', 0.5*windowLength,...
        'SpectrumType', 'psd',...
        'Window', hamming(windowLength)));
    
 progBar = progress('Computing EEG Power Spectra');
 for a = 1:length(channels)
     % Generate a spectrum for the current channel
     specStruct.Spectrum.Channels = channels(a);
     spectralData = spectralObj(specStruct);
     
     % Store the spectrum & average spectrum
     store(spectralData);
     meanSpectralData = mean(spectralData);
     store(meanSpectralData);

     % Plot & save the average power spectrum
     specWindow = plot(meanSpectralData);
     saveName = [imagePath '/' meanSpectralData.Channels{1}];
     saveas(specWindow.FigureHandle, [saveName '.png'], 'png');
     saveas(specWindow.FigureHandle, [saveName '.fig'], 'fig');
     close(specWindow);
     
     % Garbage collect
     clear spectralData meanSpectralData
     update(progBar, a/length(channels));
 end
 close(progBar);

 % Results
 % These spectra look similar to the original ones used in the paper draft (CSR performed, 0.01-0.08 Hz data). Dual
 % peaks are evident at approximately the same frequencies in all spectra. However, these new spectra extend out to 0.5
 % Hz, but beyond ~0.1 Hz power tends to be low. Data were plotted in linear (magnitude squared) units instead of
 % decibels/Hz. 
 
 % Notable peaks
 % AF7: 0.01953 Hz, 0.04688 Hz, 0.1133 Hz
 % C3: 0.01953 Hz, 0.04688 Hz, 0.08594 Hz
 % FPZ: 0.01953 Hz, 0.04688 Hz, 0.08594 Hz, 0.1133 Hz
 % PO8: 0.01953 Hz, 0.04688 Hz, 0.08594 Hz, 0.25 Hz, 0.2969 Hz, 0.3672 Hz
 % PO10: 0.01953 Hz, 0.04688 Hz, 0.08594 Hz, 0.1133 Hz, 0.25 Hz, 0.2969 Hz, 0.3672 Hz
 
 
 %% 0952 - See How Increasing Segment Overlap Affects Spectra (75% Overlap)
 load masterStructs
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', 'wbdcZ'), 'Path');
channels = {'AF7', 'C3', 'FPZ', 'PO8', 'PO10'};
imagePath = [fileStruct.Paths.Desktop '/EEG Power Spectra'];
 if ~exist(imagePath, 'dir'); mkdir(imagePath); end;

% Setup the window length parameter (need to capture 0.01 Hz waves)
load(eegFiles{1});
fs = eegData(1).Fs;
windowLength = (1/0.01)*fs;

specStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', [0.01 0.5],...
        'GSR', false,...
        'ParentData', {eegFiles},...
        'Scans', [],...
        'ScanState', 'RS',...
        'Subjects', []),...
    'Spectrum', struct(...
        'Channels', [],...
        'FrequencyRange', 'onesided',...
        'NFFT', 256,...
        'SegmentOverlap', 0.75*windowLength,...
        'SpectrumType', 'psd',...
        'Window', hamming(windowLength)));
    
 progBar = progress('Computing EEG Power Spectra');
 for a = 1:length(channels)
     % Generate a spectrum for the current channel
     specStruct.Spectrum.Channels = channels(a);
     spectralData = spectralObj(specStruct);
     
     % Store the spectrum & average spectrum
     store(spectralData);
     meanSpectralData = mean(spectralData);
     store(meanSpectralData);

     % Plot & save the average power spectrum
     specWindow = plot(meanSpectralData);
     saveName = [imagePath '/' meanSpectralData.Channels{1}];
     saveas(specWindow.FigureHandle, [saveName '.png'], 'png');
     saveas(specWindow.FigureHandle, [saveName '.fig'], 'fig');
     close(specWindow);
     
     % Garbage collect
     clear spectralData meanSpectralData
     update(progBar, a/length(channels));
 end
 close(progBar);
 
 % Results 
 % These spectra look nearly exactly like the spectra generated immediately above. The morphology is changed
 % very minimally, and the waveform as a whole tends to have very slightly higher power. But otherwise, no differences
 % are evident. 