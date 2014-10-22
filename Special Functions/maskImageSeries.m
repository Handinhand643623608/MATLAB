function maskedArray = maskImageSeries(array, mask, replaceWith)
% MASKIMAGESERIES - Masks a multidimensional series of images.

%% CHANGELOG
%   Written by Josh Grooms on 20141001
%       20141008:   Improved the check for mask and data array size equality.



%% Perform the Masking
% Deal with missing inputs
if nargin == 2; replaceWith = 0; end

% Ensure that the mask is logical in type
assert(islogical(mask), 'The array being used as a mask must be a logical array.');

% Get the inputted array & mask dimensionalities
szArray = size(array);
szMask = size(mask);

% If the array & mask are equivalent in size, do a simple mask
if (isequal(szArray, szMask))
    maskedArray = array .* mask;
    return;
end

% If the inputted data don't match along all but the last dimension, error out
if (szMask ~= szArray(1:end-1))
    error('The mask must be the same size as the inputted data array over all but the last dimension.');
end

% Mask the time series
maskedArray = reshape(array, [], szArray(end));
mask = mask(:);
maskedArray(~mask, :) = replaceWith;
maskedArray = reshape(maskedArray, szArray);
