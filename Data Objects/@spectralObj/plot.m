function varargout = plot(spectralData, varargin)
%PLOT Creates images of the power spectral densities from spectral data objects.
% 
%   Written by Josh Grooms on 20130910
%       20131126:   Bug fix for not properly plotting in decibels.
%       20140205:   Implemented an option for plotting in linear (magnitude squared) or logarithmic (decibel) units.
%                   Implemented the ability to plot significance thresholds. Implemented the use of the relatively new
%                   function SHADEPLOT to make plotting easier. 


%% Initialize
inStruct = struct(...
    'Thresholding', 'off',...
    'Units', 'Mag^2');
assignInputs(inStruct, varargin);

% Get the data field names for plotting
dataNames = spectralData.Channels;

% Generate strings to label plots
titleStr = 'Average %s Welch Power Spectral Density';
xLabelStr = 'Frequency (Hz)';
yLabelStr = '%s';


%% Plot the Data
for a = 1:length(dataNames)    
    % Get the current data set
    currentMean = spectralData.Data.(dataNames{a}).Mean;
    currentSEM = spectralData.Data.(dataNames{a}).SEM;
    frequencies = spectralData.Data.Frequencies;
    
    % Convert to logarithmic units, if called for
    if any(strcmpi(Units, {'db/Hz', 'db'}))
        currentMean = 10*log10(currentMean);
        currentSEM = 10*log10(currentSEM);
    end
    
    % Plot the data (either thresholded or unthresholded)
    if istrue(Thresholding) && isfield(spectralData.Parameters, 'SignificanceCutoffs')
        windowHandle(a) = shadePlot(frequencies, currentMean, currentSEM, '-k',...
            'Threshold', currentCutoff,...
            'Title', sprintf(['Thresholded ' titleStr], dataNames{a}),...
            'XLabel', xLabelStr,...
            'YLabel', sprintf(yLabelStr, Units));
    else
        windowHandle(a) = shadePlot(frequencies, currentMean, currentSEM, '-k',...
            'Title', sprintf(titleStr, dataNames{a}),...
            'XLabel', xLabelStr,...
            'YLabel', sprintf(yLabelStr, Units));
    end
end

assignOutputs(nargout, windowHandle);