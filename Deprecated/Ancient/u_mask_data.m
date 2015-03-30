function outImage = u_mask_image(inImage, maskImage, confPct)
% F_MASK_DATA takes an input image and masks it with an input mask. 
%   Designed for use with fMRI data of format (x, y, z, t).
% 
%   Syntax:
%   image_out = f_mask_data(data_image, mask_image, conf_pct)
% 
%   IMAGE_OUT: the output masked image
%   DATA_IMAGE: the input data image of form (x, y, z, t)
%   MASK_IMAGE: the mask image to be applied to the data image. Must be in 
%               the same format as the input: (x, y, z)
%   CONF_PCT: (OPTIONAL) percent confidence of the mask being applied (e.g. for 90% GM
%                        mask, input "0.9" for this number, which is the default)
% 
%       Written by Josh Grooms on 5/25/2012

%% Initialize
% Default to the 90% confidence level for the mask, if not provided
if nargin < 3
    confPct = 0.9;
end

% Determine the number of dimensions of the data
numDims = length(size(inImage));

% Threshold the mask image
confMask = zeros(size(maskImage));
confMask(maskImage > confPct) = 1;

% Allocate the output image
outImage = zeros(size(inImage));

%% Mask the data
switch numDims
    case 3
        inImage(confMask ~= 1) = NaN;
        outImage = inImage;
    case 4        
        for i = 1:size(inImage, 4)
            currentData = inImage(:, :, :, i);
            currentData(confMask ~= 1) = NaN;
            outImage(:, :, :, i) = currentData;
        end

    case 5
        for i = 1:size(inImage, 5)
            for j = 1:size(inImage, 4)
                currentData = inImage(:, :, :, j, i);
                currentData(confMask ~=1) = NaN;
                outImage(:, :, :, j, i) = currentData;
            end
        end
        
    otherwise
        error('Input image data is not in a recognized format')
end
