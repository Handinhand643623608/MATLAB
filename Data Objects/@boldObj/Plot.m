function varargout = Plot(boldData, varargin)
%PLOT Plots BOLD functional data to an image montage.
%
%   SYNTAX:
%   Plot(boldData)
%   Plot(boldData, 'PropertyName', PropertyValue,...)
%   H = Plot(...)
%
%   OPTIONAL OUTPUT:
%   H:              BRAINPLOT or [BRAINPLOT]
%                   The handle of the plot object that contains the BOLD image montage. A number of properties and
%                   settings are available through this object to change the appearance and content of the plot. If
%                   multiple BOLD data objects are inputted, this will be an array of plot handles with one handle per
%                   data object. Each BOLD data set will get its own separate image montage.
%
%   INPUTS:
%   boldData:       BOLDOBJ or [BOLDOBJ]
%                   A BOLD data object or array of objects to be plotted. If multiple data objects are provided in an
%                   array, a separate image montage will be generated for each one of the data sets.
%   
%
%   OPTIONAL INPUT:
%   'CLim':         [DOUBLE, DOUBLE]
%                   A two-element vector specifying the [MIN, MAX] values that will be mapped to color extremes shown on
%                   the plot. In other words, using the Jet colormap as an example, the MIN value will be mapped to the
%                   deepest blue available while the MAX value will be mapped to the deepest red being displayed. Values
%                   in the data falling outside of this range will be displayed as the minimum/maximum colors available.
%                   The default value of this parameter is what I typically use when examining z-scored BOLD data.
%                   DEFAULT: [-3, 3]
%
%   'Slices':       INTEGER VECTOR
%                   A vector of slice numbers to include in the plot. The elements of this vector must be integers, must
%                   be greater than zero, and must be less than the total size of the functional array in the Z
%                   direction. Any and all slices can be included in this parameter, in theory. However, too many slices
%                   will result in an unreadable plot. It is usually best to have this function plot 10 slices or less
%                   in total.
%                   DEFAULT: 48:4:64
%   
%   'Threshold':    DOUBLE or [DOUBLE, DOUBLE]
%                   A single value or two values that are used to threshold BOLD voxel intensities. Threshold values are
%                   specified in the format [MIN, MAX]. Inputting only one value for this parameter results in
%                   thresholds of [-VALUE, VALUE] being used. Either way, any voxel whose intensity lies in between the
%                   two values is removed from the resulting plot and replaced with voxels from a generic anatomical
%                   brain (the Colin brain). Thus, if this parameter is used, the only color that will appear in the
%                   image comes from voxels whose intensities are lower than the minimum threshold or greater than the
%                   maximum. Inputting an empty array for this parameter results in no thresholding of the data.
%                   DEFAULT: []
%
%   'Times':        INTEGER VECTOR
%                   A vector of time points to include in this plot. The elements of this vector must be integers and
%                   must be in units of samples (not in seconds). Any and all time points can be included in this
%                   parameter. However, including more than about 20 time points in total usually results in an
%                   unreadable plot. 
%                   DEFAULT: ~21 time points evenly spaced over the whole time series

%% CHANGELOG
%   Written by Josh Grooms on 20140613
%       20140625:   Removed dependencies on my personal file structure (mostly from brainPlot). Implemented the ability
%                   to threshold BOLD images being plotted. Implemented automatic loading and conditioning of the Colin
%                   brain volume as the default anatomical underlay. Updated the documentation for this function.
%       20140626:   Updated to use linspace to generate the default time points to be plotted. Implemented a conversion
%                   of zeros to NaNs for the plot in case that hasn't already been done.



%% Make an Image Montage of the BOLD Data
% Initialize a defaults & settings structure
numTime = size(boldData(1).Data.Functional, 4);
inStruct = struct(...
    'CLim', [-3 3],...
    'Slices', [48:4:64],...
    'Threshold', [],...
    'Times', round(linspace(1, numTime, 21)));
assignInputs(inStruct, varargin);

% If data is thresholded, initialize the anatomical underlay & make some histogram adjustments
if ~isempty(Threshold)
    load colinBrain;
    colinBrain = colinBrain(:, :, Slices);
    colinMask = colinMask(:, :, Slices);
    colinBrain(colinMask == 0) = 0;
    colinBrain(colinBrain > 5e6) = 4.5e6;
    colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;
else
    colinBrain = [];
end

for a = 1:numel(boldData)
    % Convert times in samples to times in seconds for display
    timesSeconds = Times*(boldData(a).TR/1000);
    
    % Format the plot title string
    titleStr = sprintf('Subject %d Scan %d BOLD Data', boldData(a).Subject, boldData(a).Scan);
    
    % Get & format the functional data being plotted
    funData = ToArray(boldData(a));
    funData = funData(:, :, Slices, Times);
    funData(funData == 0) = NaN;
    if ~isempty(Threshold)
        funData(colinMask == 0) = NaN;
        funData(funData > Threshold(1) & funData < Threshold(2)) = NaN;
    end
    
    % Create a colorbar label
    cbarLabel = 'Arbitrary Units';
    if boldData(a).IsZScored; cbarLabel = 'Z-Scores'; end
        
    % Plot the image montage
    brainData(a) = brainPlot('mri', funData,...
        'Anatomical', colinBrain,...
        'CLim', CLim,...
        'ColorbarLabel', cbarLabel,...
        'Title', titleStr,...
        'XLabel', 'Time (s)',...
        'XTickLabel', timesSeconds,...
        'YLabel', 'Slice Number',...
        'YTickLabel', Slices);
end

assignOutputs(nargout, brainData)