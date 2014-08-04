function Blur(boldData, hsize, sigma)
%BLUR Spatially Gaussian blur BOLD image series.
%
%   SYNTAX:
%   Blur(boldData, hsize, sigma)
%
%   INPUTS:
%   boldData:       BOLDOBJ
%                   A BOLD data object.
%
%   hsize:          INTEGER or [INTEGER, INTEGER]
%                   An integer or 2-element vector of integers representing the size (in [HEIGHT, WIDTH] pixels) of the
%                   Gaussian used to blur the data. A single scalar input generates a symmetric Gaussian.
%
%   sigma:          DOUBLE
%                   The standard deviation (in pixels) of the Gaussian used to blur the data. This must be a single
%                   double-precision value.

%% CHANGELOG
%   Written by Josh Grooms on 20130919
%       20140612:   Updated the documentation for this method.


%% Apply a Gaussian Blur
% Generate filter specifications
blurFilterSpec = fspecial('gaussian', hsize, sigma);

% Loop through each scan
for a = 1:numel(boldData)
    % Get the functional data
    functionalData = ToArray(boldData(a));
    for b = 1:size(functionalData, 4) 
        functionalData(:, :, :, b) = imfilter(functionalData(:, :, :, b), blurFilterSpec);
    end
    
    % Blur the segment data
    segmentStrs = fieldnames(boldData(a).Data.Segments);
    for b = 1:length(segmentStrs)
        boldData(a).Data.Segments.(segmentStrs{b}) = imfilter(boldData(a).Data.Segments.(segmentStrs{b}), blurFilterSpec);
    end
    
    % Store the blurred data
    boldData(a).Data.Functional = functionalData;
    boldData(a).ZScored = false;
end