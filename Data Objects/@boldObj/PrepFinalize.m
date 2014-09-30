function PrepFinalize(boldData)



%% CHANGELOG
%   Written by Josh Grooms on 20140930



%% Initialize
params = mergestructs(...
    boldData.Preprocessing.SegmentThreshold,...
    boldData.Preprocessing.SignalCropping);



%% Finalize the Segmented Anatomical Data
% Normalize the mean functional image values to between 0 & 1
meanData = boldData.Data.Mean;
minMean = min(meanData(:));
boldData.Data.Mean = (meanData - minMean) ./ (max(meanData(:)) - minMean);

% Convert the mean functional image into a mask
idsBrain = meanData > params.MeanImageCutoff;

% Mask & normalize the segments
for a = 1:size(boldData.Data.Segments, 4)
    segData = boldData.Data.Segments(:, :, :, a);
    minSeg = min(segData(:));
    segData = (segData - minSeg) ./ (max(segData(:)) - minSeg);
    boldData.Data.Segments(:, :, :, a) = single(segData .* idsBrain);
end

% Store the thresholded mean image as a mask
boldData.Data.Masks.Mean = logical(idsBrain);



%% Finalize the Functional Data
% Mask the functional data using the mean image & crop out the specified number of TRs
boldData.Mask(idsBrain);
boldData.Data.Functional = boldData.Data.Functional(:, :, :, params.NumTimePointsToRemove + 1:end);
boldData.Data.Nuisance.Motion = boldData.Data.Nuisance.Motion(:, params.NumTimePointsToRemove + 1:end);


