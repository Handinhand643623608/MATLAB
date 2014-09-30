function varargout = Mask(boldData, maskData, confPct, replaceWith)
% MASK - Masks BOLD images with the input probability mask.
%   This function masks BOLD data using a specified probability mask (e.g. gray matter segment mask) and sets all
%   spatial and temporal data outside of the mask equal to zero. It then returns an output BOLD image that is the same
%   size as the input.
%
%   SYNTAX:
%   Mask(boldData, maskData)
%   Mask(boldData, maskData, confPct)
%   Mask(bolDData, maskData, confPct, replaceWith)
%   idsMask = Mask(...)
%
%
%   OPTIONAL OUTPUT:
%   idsMask:        3D ARRAY
%                   A 3-dimensional image with Booleans representing where BOLD data passed thresholding. 
%
%   INPUTS:
%   boldData:       BOLDOBJ
%                   The BOLD data object containing functional data to be masked.
%
%   maskData:       3D ARRAY or STRING
%                   The mask probability or logical map. This may be a gray matter segment image or a mask of the user's
%                   design. This image must be the same size as the BOLD image over the spatial dimensions. If using a
%                   Boolean mask, make sure that the inputted image is of type LOGICAL.
%
%                   OPTIONS:
%                       3D ARRAY - An array of numbers whose size matches BOLD data over the first three dimensions.
%                       'GM'     - Use the gray matter segmentation mask stored in the BOLD object.
%                       'WM'     - Use the white matter segmentation mask stored in the BOLD object.
%                       'Mean'   - Use the average BOLD image stored in the BOLD object.
%                       'CSF'    - Use the cerebrospinal fluid segmentation mask stored in the BOLD object.
%
%
%   OPTIONAL INPUT:
%   confPct:        SCALAR
%                   A scalar that thresholds the input mask image. If inputting a logical mask, no threshold is needed.
%                   If inputting a probability map, this value can be specified between 0 and 1.
%                   DEFAULT: 0.9
%
%   replaceWith:    SCALAR or NaN
%                   A scalar or NaN that will replace all image values not passing the mask threshold.
%                   DEFAULT: 0

%% CHANGELOG
%   Written by Josh Grooms on 20130818
%       20130906:   Bug fix for treating boldData as an image instead of an object. Added output for mask image (for 
%                   reconstructing BOLD images).
%       20130919:   Updated to work for arrays of BOLD objects.
%       20140612:   Added an error check to ensure that the mask and BOLD data dimensions match before masking. Improved
%                   documentation for this method. 
%       20140801:   Updated to work with the new MATFILE storage system.



%% Initialize
% Default to the 90% confidence level for the mask, if not provided
if nargin == 2 && ~islogical(maskData)
    confPct = 0.9;
elseif nargin == 2 && islogical(maskData)
    confPct = 0;
elseif nargin == 3
    replaceWith = 0;
end

maskDataStr = '';
if ischar(maskData); maskDataStr = maskData; end



%% Mask the Functional Data
for a = 1:numel(boldData)
    
    % Load any MATFILE data
    LoadData(boldData(a));
    
    % Deal with string inputs for masks
    switch lower(maskDataStr)
        case {'mean', 'average'}
            maskData = boldData(a).Data.Mean;
        case {'gray', 'grey', 'gm', 'graymatter', 'greymatter'}
            maskData = boldData(a).Data.Segments.GM;
        case {'white', 'wm', 'whitematter'}
            maskData = boldData(a).Data.Segments.WM;
        case {'csf'}
            maskData = boldData(a).Data.Segments.CSF;
    end
    
    % Flatten the current functional data set
    functionalData = ToMatrix(boldData(a));
    szBOLD = size(boldData(a).Data.Functional);
    
    % Flatten the mask to match the functional data
    maskData = reshape(maskData, [], 1);
    
    % Do a quick error check for proper data dimensions
    if ~isequal(size(maskData, 1), size(functionalData, 1))
        error('The spatial dimensions of the mask and BOLD data must match');
    end
    
    % Perform the masking
    idsMask = double(maskData) > confPct;
    functionalData(~idsMask, :) = replaceWith;

    % Reshape the data to input sizing
    boldData(a).Data.Functional = reshape(functionalData, szBOLD);
    idsMask = reshape(idsMask, szBOLD(1:3));
    
end

% Generate function outputs
assignOutputs(nargout, idsMask);
