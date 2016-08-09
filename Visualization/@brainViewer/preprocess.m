function preprocess(brainData)
%PREPROCESS
%
%   Written by Josh Grooms on 20131208


%% Initialize
% Pull volume & mask data from the data object, or generate a mask if one isn't available
volumeData = brainData.Data.Anatomical;
if ~isempty(brainData.Data.Mask)
    maskData = brainData.Data.Mask;
else
    % Generate a mask
    numColors = 2;
    minData = min(volumeData(:));
    maxData = max(volumeData(:));
    maskData = round((numColors - 1)*(volumeData - minData)/(maxData - minData));
    maskData = logical(maskData);
end


%% Anatomical Image Corrections
% Erode the brain mask (gets rid of a lot of artifacts) & mask anatomical data
structEl = strel('disk', brainData.Parameters.StrelRadius, 0);
maskData = imerode(maskData, structEl);
volumeData(~maskData) = 0;

% % Histogram correction for major outliers
tempData = volumeData(:);
tempData(tempData == 0) = [];
lowerPct = prctile(tempData, 1);
upperPct = prctile(tempData, 99);
volumeData(volumeData <= lowerPct | volumeData >= upperPct) = 0;

% Keep track of zeros in the data
idsZeros = volumeData == 0;


%% Anatomical Image Coloration
% Get the number of colors in the color mapping
numColors = get(brainData.FigureHandle, 'Colormap');
numColors = size(numColors, 1);

% Generate color mapping indices for each anatomical data point
minData = min(volumeData(:));
maxData = max(volumeData(:));
volumeData = (volumeData - minData)./(maxData - minData);
minData = min(volumeData(:));
maxData = max(volumeData(:));
colorData = ((numColors-1)*(volumeData - minData))./(maxData - minData) + 1;

% Data points with a value of zero should be transparent
colorData(idsZeros) = 0;
volumeData(idsZeros) = 0;


%% Store Data in the Data Object
brainData.Data = addfield(brainData.Data,...
    'Anatomical', volumeData,...
    'Color', colorData);
