function varargout = mask(corrData, maskData, confPct, replaceWith)
%MASK Masks correlation images with the input probability mask.
%   This function masks correlation data using a specified probability mask (e.g. gray matter
%   segment mask) and sets all spatial and temporal data outside of the mask equal to zero. It then
%   returns an output correlation image that is the same size as the input.
%
%   SYNTAX:
%   mask(corrData, maskData)
%   mask(corrData, maskData, confPct)
%   mask(corrData, maskData, confPct, replaceWith)
%   idsMask = mask(...)
%
%   OPTIONAL OUTPUT:
%   idsMask:        [X Y Z]
%                   A 3-dimensional image with Booleans representing where correlation data passed
%                   thresholding.
%
%   INPUTS:
%   corrData:       CORROBJ
%                   The correlation data object that is to be masked.
%
%   maskData:       [X Y Z]
%                   The mask probability or logical map. This may be a gray matter segment image or
%                   a mask of the user's design. This image must be the same size as the correlation
%                   data image over the spatial dimensions. If using a Boolean mask, make sure that
%                   the inputted image is of type LOGICAL.
%
%   OPTIONAL INPUT:
%   confPct:        [X]
%                   A scalar that thresholds the input mask image. If inputting a logical mask, no
%                   threshold is needed. If inputting a probability map, this value can be specified
%                   between 0 and 1.
%                   DEFAULT: 0.9
%
%   replaceWith:    [X]
%                   A scalar or NaN that will replace all image values not passing the mask
%                   threshold.
%                   DEFAULT: 0
%
%   Written by Josh Grooms on 20130717
%       20130917:   Re-written to mask correlation data objects instead of BOLD (which has been
%                   made its own method under that object).


%% Initialize
% Default to the 90% confidence level for the mask, if not provided
if nargin == 2 && ~islogical(maskData)
    confPct = 0.9;
elseif nargin == 2 && islogical(maskData)
    confPct = 0;
elseif nargin == 3
    replaceWith = 0;
end

% Get data properties
dataFields = fieldnames(corrData.Data);
szCorr = size(corrData.Data.(dataFields{1}));

% Error check
if ~isequal(szCorr(1:end-1), size(maskData))
    error('The BOLD image & mask must be the same size over the spatial dimensions');
end
if confPct > 1 || confPct < 0
    error('The mask threshold value must lie between 0 and 1. See documentation for help');
end


%% Mask all Data Fields
for a = 1:length(dataFields)
    % Get the current correlation data set
    currentCorr = corrData.Data.(dataFields{a});
    szCorr = size(currentCorr);
    
    % Flatten the data, preserving the time dimension
    currentCorr = reshape(currentCorr, [], szCorr(end));
    maskData = reshape(maskData, [], 1);
    
    % Perform the masking
    idsMask = double(maskData) > confPct;
    currentCorr(~idsMask, :) = replaceWith;
    
    % Reshape the data to input sizing
    corrData.Data.(dataFields{a}) = reshape(currentCorr, szCorr);
    idsMask = reshape(idsMask, szCorr(1:3));
end

% Generate function outputs
assignOutputs(nargout, idsMask)