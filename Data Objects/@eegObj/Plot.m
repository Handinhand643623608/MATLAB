function varargout = Plot(eegData, varargin)
%PLOT - Plots EEG signals to an image montage.
%
%   SYNTAX:
%   Plot(eegData)
%   Plot(eegData, 'PropertyName', PropertyValue,...)
%   H = Plot(...)
%
%   OPTIONAL OUTPUT:
%   H:              BRAINPLOT or [BRAINPLOT]
%                   The handle of the plot objects that contains the colored EEG channel map montage. A number of
%                   properties and settings are available through this object to change the appearance and content of
%                   the plot. If multiple EEG data objects are inputted, this will be an array of plot handles with one
%                   handle per data object. Each EEG data set will get its own separate image montage.
%
%   INPUT:
%   eegData:        EEGOBJ or [EEGOBJ]
%                   An EEG data object or array of objects to be plotted. If multiple data objects are provided as an
%                   array, a separate image montage will be generated for each one of the data sets.
%
%   OPTIONAL INPUT:
%   'CLim':         [DOUBLE, DOUBLE]
%                   A two-element vector specifying the [MIN, MAX] values that will be mapped t ocolor extremes shown on
%                   the plot. In other words, using the Jet colormap as an example, the MIN value will be mapped to the
%                   deepest blue available while the MAX value will be mapped to the deepest red being displayed. Values
%                   in the data falling outside of this range will be clamped to the minimum/maximum colors available.
%                   The default value of this parameter assumes that the inputted EEG data have been z-scored.
%                   DEFAULT: [-3 3]
%
%   'Times':        INTEGER VECTOR
%                   A vector of time points to include in this plot. The elements of this vector must be integers and
%                   must be in units of samples (not in seconds). Any and all time points can be included in the
%                   parameter. However, including more than about 20 time points in total usually results in an
%                   unreadable plot.
%                   DEFAULT: ~21 time points evenly spaced over the whole time series

%% CHANGELOG
%   Written by Josh Grooms on 20140716
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).



%% Make an Image Montage of the EEG Data
% Initialize a defaults & settings structure
numTime = size(eegData(1).Data.EEG, 2);
inStruct = struct(...
    'CLim', [-3 3],...
    'Times', round(linspace(1, numTime, 21)));
assignInputs(inStruct, varargin);

for a = 1:numel(eegData)
    % Convert times in samples to times in seconds for display
    timesSeconds = Times.*(eegData(a).Fs);
    
    % Format the plot title string
    titleStr = sprintf('Subject %d Scan %d EEG Data', eegData(a).Subject, eegData(a).Scan);
    
    % Get & format the EEG data being plotted
    ephysData = ToArray(eegData(a));
    ephysData = ephysData(:, Times);
    
    % Create a colorbar label
    cbarLabel = 'Arbitrary Units';
    if eegData(a).IsZScored; cbarLabel = 'Z-Scores'; end
    
    % Plot the image montage
    brainData(a) = BrainPlot(ephysData,...
        'CLim', CLim,...
        'ColorbarLabel', cbarLabel,...
        'Title', titleStr,...
        'XLabel', 'Time (s)',...
        'XTickLabel', timesSeconds);
end

assignOutputs(nargout, brainData);
