function spectrum(spectralData)
%SPECTRUM Generates Welch power spectra from EEG channel data
%
%   WARNING: SPECTRUM is an internal method and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130910


%% Initialize
% Get spectral analysis input parameters
assignInputs(spectralData(1, 1).Parameters.Spectrum, 'varsOnly');


%% Generate the Spectral Data
% Set up progress bars
progStrs = {'Generating Welch Power Spectra';
            'Scans Completed'};
progBar = progress(progStrs{:});

previousDataSet = '';
for a = 1:size(spectralData, 1)
    reset(progBar, 2);
    for b = 1:size(spectralData, 2)
        if ~isempty(spectralData(a, b).ParentData)
            
            % Load the parent data sets         
            if ~strcmpi(previousDataSet, spectralData(a, b).ParentData);
                load(spectralData(a, b).ParentData);
            end
            
            % Get the EEG channel data
            currentChannelData = extract(eegData(b), Channels);
            
            % Loop through channels & generate spectra
            for c = 1:size(currentChannelData, 1)
                [currentSpectrum, frequencies] = pwelch(currentChannelData(c, :),...
                    Window,...
                    SegmentOverlap,...
                    NFFT,...
                    eegData(b).Fs,...
                    FrequencyRange,...
                    SpectrumType);
                spectralData(a, b).Data.(Channels{c}) = currentSpectrum';
            end            

            % Store information in the spectral data object
            spectralData(a, b).Data.Frequencies = frequencies';
            spectralData(a, b).Acquisition = eegData(b).Acquisition;
            spectralData(a, b).Bandwidth = [frequencies(1) frequencies(end)];
            spectralData(a, b).Preprocessing = eegData(b).Preprocessing;
            spectralData(a, b).Channels = Channels;
            spectralData(a, b).Fs = eegData(b).Fs;

        end
        update(progBar, 2, b/size(spectralData, 2));
    end
    update(progBar, 1, a/size(spectralData, 1));
end
close(progBar)
            
            
end%================================================================================================
%% Nested Functions
% Extract needed data from the EEG data object
function extractedData = extract(eegData, channels)
    idsChannels = ismember(eegData.Channels, channels);
    extractedData = eegData.Data.EEG(idsChannels, :);
end