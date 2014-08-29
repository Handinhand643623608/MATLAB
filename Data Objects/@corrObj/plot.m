function varargout = plot(corrData, varargin)
%PLOT Plot the correlation data.
%   This function plots the correlation data between EEG and fMRI modalities. Most of the process is completely
%   automated, and so only the correlation data object needs to be supplied.
%
%   If changes to the plot are desired, an output can be requested durings calls to PLOT. This output is a handle to the
%   brainPlot object that the data are plotted to. See documentation for that function for properties that can be
%   manipulated.
%
%   WARNING: this function does not yet support single-subject plots
%
%   SYNTAX:
%   plot(corrData)
%   brainData = plot(corrData)
%
%   OPTIONAL OUTPUT:
%   brainData:          The brainPlot data object with properties dictating the presentation of the graphic.
%
%   INPUT:
%   corrData:           A correlation data object. 
%                       WARNING: this can only currently be an averaged correlation object.
%
%   OPTIONAL INPUT:
%   'CLim':             A two-element vector specifying the [MIN MAX] in data units to be mapped to color extremes. By 
%                       default, this parameter is calculated automatically using absolute data extremes. 
%                       DEFAULT: []
%
%   'ColorbarLabel':    The vertical text label for the colorbar
%                       DEFAULT: 'Pearson Correlation Coefficient'
%
%   'Slices':           The slices of fMRI-type data to be plotted along the y-axis of the plot. This parameter only 
%                       matters if the input data array is formatted like MRI data (e.g. size [91x109x91x218]). 
%                       DEFAULT: [48:4:64]
%
%   'TimeShifts':       The specific time shifts of correlation to plot. Input this parameter as the specific time 
%                       shifts (in seconds) themselves, and not as indices into the time shifts vector. The default
%                       value for this parameter is all available shifts. 
%                       DEFAULT: [MinLag:MaxLag]
%
%   'Thresholding':     A boolean indicating whether or not to plot thresholded data. Turning this  on will result in 
%                       an error if data has not yet been thresholded.
%                       DEFAULT: 'off' OR false
%
%   'XLabel':           The x-axis label string (same as the built-in axes property).
%                       DEFAULT: 'Time Shifts (s)'
%
%   'XTickLabel:        The x-axis tick labels (same as the built-in axes property).
%                       DEFAULT: [MinLag:MaxLag]
%
%   'YLabel':           The y-axis label string (same as the built-in axes property). This will typically be either 
%                       'Slice Number' if plotting MRI-style data. 
%                       DEFAULT: []
%
%   'YTickLabel':       The y-axis tick labels (same as the built-in axes property). 
%                       DEFAULT: []

%% CHANGELOG
%   Written by Josh Grooms on 20130702
%       20130711:   Implemented automatic plotting of correlation data for MRI-style plots. Reorganized defaults & 
%                   settings structure. Simplified title string generation. Added error checking. Implemented ability to
%                   plot specific slice & time shift ranges. Re-wrote help & reference section.
%       20130717:   Added in anatomical image loading for thresholded MRI images.
%       20130906:   Updated for compatibility with improved correlation & initialization code.
%       20131126:   Implemented BOLD-RSN correlations to test how well ICA is doing its job. Implemented plotting of the
%                   MNI Colin Brain as the anatomical underlay image for thresholded data.
%       20131222:   Implemented BOLD-Motion nuisance parameter correlation plotting.
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).


%% Initialize
% Assign inputs and override defaults
inStruct = struct(...
    'CLim', [],...
    'ColorbarLabel', 'Z-Scores',...
    'Slices', [48:4:64],...
    'TimeShifts', [corrData(1, 1).Parameters.Correlation.TimeShifts],...
    'Thresholding', 'off',...
    'XLabel', 'Time Shifts (s)',...
    'XTickLabel', [corrData(1, 1).Parameters.Correlation.TimeShifts],...
    'YLabel', [],...
    'YTickLabel', []);
assignInputs(inStruct, varargin, 'structOnly');

% Error out if certain conditions are not met
if ~isscalar(corrData)
    error(['This function does not yet support plotting of single subjects. '...
          'Run MEAN on the data first in order to plot it']);
end
if istrue(inStruct.Thresholding) && ~isfield(corrData.Parameters, 'SignificanceCutoffs')
    error(['Data must be thresholded in order plot significant data points. '... 
           'Turn off "Thresholding" or run THRESHOLD on the data to use this option']);
end

% Initialize which of these defaults fields should not be transferred to brainPlot
exclusionStrs = {'Slices', 'TimeShifts', 'Thresholding'};

% Get information from the input object
dataStrs = corrData(1, 1).Parameters.Correlation.DataStrs;

% Correct the x-tick labels, if the user supplies different time shifts
if length(inStruct.TimeShifts) ~= length(inStruct.XTickLabel)
    inStruct.XTickLabel = inStruct.TimeShifts;
end
timeShiftsToPlot = ismember(corrData(1, 1).Parameters.Correlation.TimeShifts, inStruct.TimeShifts);

% Configure the plot title
titleStr = ['%s-%s ' corrData(1, 1).Relation 's'];
if corrData.Averaged
    titleStr = ['Averaged ' titleStr];
end
if istrue(inStruct.Thresholding)
    titleStr = ['Thresholded ' titleStr];
end

%% Plot the Data
switch lower(corrData(1, 1).Modalities)
    case 'bold nuisance-eeg'
        
        % Initialize plot parameters
        plotType = 'eeg';
        
        % Initialize data arrays to pass over to plotting function
        motionData = corrData.Data.Motion;
        nuisanceData = [];
        
        for a = 1:length(dataStrs)
            switch dataStrs{a}
                case 'Motion'
                    if istrue(inStruct.Thresholding)
                        cutoffs = corrData.Parameters.SignificanceCutoffs.(dataStrs{a});
                        motionData(motionData > cutoffs(1) & motionData < cutoffs(2)) = 0;
                    end
                otherwise
                    tempData = corrData.Data.(dataStrs{a});
                    if istrue(inStruct.Thresholding)
                        cutoffs = corrData.Parameters.SignificanceCutoffs.(dataStrs{a});
                        tempData(tempData > cutoffs(1) & tempData < cutoffs(2)) = 0;
                    end
                    nuisanceData = cat(3, nuisanceData, tempData);
            end
        end
       
        % Plot the motion parameters
        segCorrMods = segmentModalities(corrData(1, 1).Modalities);
        inStruct.Title = sprintf(titleStr, 'Motion Parameters', segCorrMods{2});
        inStruct.YLabel = 'Motion Parameters';
        inStruct.YTickLabel = 1:6;
        plotVars = struct2var(inStruct, exclusionStrs);
        montageData = BrainPlot(motionData, plotVars{:});
        
        % Plot the rest of the nuisance signals
        inStruct.Title = sprintf(titleStr, 'Nuisance Parameters', segCorrMods{2});
        inStruct.YLabel = 'Nuisance Parameters';
        inStruct.YTickLabel = dataStrs(2:end);
        plotVars = struct2var(inStruct, exclusionStrs);
        montageData(2) = BrainPlot(nuisanceData, plotVars{:});
        
    case {'bold-eeg', 'bold-bold nuisance', 'bold-motion', 'bold-rsn', 'bold-global'}
        
        % Initialize plot parameters
        plotType = 'mri';
        segCorrMods = segmentModalities(corrData(1, 1).Modalities);
        if istrue(inStruct.Thresholding)
            load('C:\Users\Josh\Dropbox\svnSandbox\Special Functions\@brainViewer\colinBrain.mat');
            anatomicalImage = colinBrain(:, :, inStruct.Slices);
        else
            anatomicalImage = [];
        end
        
        for a = 1:length(dataStrs)
            % Get the data array to pass over to the plotting function & threshold if called for
            tempData = corrData.Data.(dataStrs{a})(:, :, inStruct.Slices, timeShiftsToPlot);
            if istrue(inStruct.Thresholding)
                cutoffs = corrData.Parameters.SignificanceCutoffs.(dataStrs{a});
                tempData(tempData > cutoffs(1) & tempData < cutoffs(2)) = NaN;
            end
           
            % Finalize plot parameters
            inStruct.Title = sprintf(titleStr, segCorrMods{1}, dataStrs{a});
            inStruct.YLabel = 'Slice Number';
            inStruct.YTickLabel = inStruct.Slices;
            plotVars = struct2var(inStruct, exclusionStrs);
            montageData(a) = BrainPlot(tempData, plotVars{:}, 'Anatomical', anatomicalImage);
        end
        
    case 'rsn-eeg'
        
        % Initialize plot parameters
        plotType = 'eeg';
        segCorrMods = segmentModalities(corrData(1, 1).Modalities);
        catData = zeros([size(corrData.Data.(dataStrs{1})), length(dataStrs)]);
        
        for a = 1:length(dataStrs)
            tempData = corrData.Data.(dataStrs{a})(:, timeShiftsToPlot);
            if istrue(inStruct.Thresholding)
                cutoffs = corrData.Parameters.SignificanceCutoffs.(dataStrs{a});
                tempData(tempData > cutoffs(1) & tempData < cutoffs(2)) = 0;
            end
            catData(:, :, a) = tempData;
        end

        % Finalize plot parameters
        inStruct.Title = sprintf(titleStr, segCorrMods{1}, segCorrMods{2});
        inStruct.YLabel = 'Resting State Network';
        inStruct.YTickLabel = dataStrs;
        plotVars = struct2var(inStruct, exclusionStrs);
        montageData = BrainPlot(catData, plotVars{:});
end

% Generate outputs
assignOutputs(nargout, montageData);


end%====================================================================================================================
%% Nested Functions
% Segment modalities string into parsable cells
function modalities = segmentModalities(modalities)
    modalities = regexpi(modalities, '([^-]*)', 'tokens');
    modalities = cat(2, modalities{:});
end