function varargout = plot(cohData, varargin)
%PLOT Displays the coherence data object using specified inputs.
%   This function automatically displays the coherence data contained within the data object in a
%   two dimensional plot. It includes a dashed line for the statistical significance cutoff and thin
%   lines above and below the data line for standard error visualization. The color scheme of this
%   plot is the only editable feature at this time. All colors are specifiable as either MATLAB
%   color strings (e.g. 'b') or as RGB vectors. 
%
%   This function also automatically saves the plots to the appropriate folder under the "Results"
%   field of the master file structure. It saves both a .fig file and a file that can be specified
%   by the user (default .png).
%
%   SYNTAX:
%   plot(cohData, 'PropertyName', PropertyValue...)
%
%   OPTIONAL INPUTS:
%   'AxesColor':            The color of the axes lines and associated text labels.
%                           DEFAULT: 'w'
%
%   'Color':                The color of the axes and figure background.
%                           DEFAULT: 'k'
%
%   'CutoffColor':          The color of the dashed line indicating the statistical significance
%                           cutoff. 
%                           DEFAULT: 'r'
%
%   'DataColor':            The color of the thick central line representing the coherence data. 
%                           DEFAULT: 'b'
%
%   'ErrorColor':           The color of the thin error lines (if error is present).
%                           DEFAULT: 'g'
%
%   'ImageFormat':          The format of the image file to be saved to the hard disk. Images are
%                           always saved as .fig files first, but can also be saved as a format
%                           specified here.
%                           DEFAULT: 'png'
%
%
%   Written by Josh Grooms on 20130614
%       20140205:   Radical overhaul of function to remove various options that were never used. Implemented the use of 
%                   the relatively new function SHADEPLOT. Hard coded color schemes & line weightings. Removed this
%                   function's ability to save images (this should be implemened outside). 


%% Initialize a Defaults & Settings Structure
% Default settings & values
inStruct = struct(...
    'Thresholding', 'off');
assignInputs(inStruct, varargin);

% Get the data field names
dataNames = cohData.Parameters.Coherence.Channels;

% Generate strings to label plots
titleStr = 'Average %s-BOLD %s';
xLabelStr = 'Frequency (Hz)';
yLabelStr = 'MS Coherence';


%% Plot the Data
for a = 1:length(dataNames)    
    % Get the current data set
    currentMean = cohData.Data.(dataNames{a}).Mean;
    currentSEM = cohData.Data.(dataNames{a}).SEM;
    frequencies = cohData.Parameters.Coherence.Frequencies;
    
    % Plot the data (either thresholded or unthresholded)
    if istrue(Thresholding) && isfield(cohData.Parameters, 'SignificanceCutoffs')
        currentCutoff = cohData.Parameters.SignificanceCutoffs.(dataNames{a});
        windowHandle(a) = shadePlot(frequencies, currentMean, currentSEM, '-k',...
            'Threshold', currentCutoff,...
            'Title', sprintf(['Thresholded ' titleStr], dataNames{a}, cohData.Relation),...
            'XLabel', xLabelStr,...
            'YLabel', yLabelStr);
    else
        windowHandle(a) = shadePlot(frequencies, currentMean, currentSEM, '-k',...
            'Title', sprintf(titleStr, dataNames{a}, cohData.Relation),...
            'XLabel', xLabelStr,...
            'YLabel', yLabelStr);
    end
end

assignOutputs(nargout, windowHandle);
