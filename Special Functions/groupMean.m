function meanData = groupMean(inData, numPerGroup, dim)
%GROUPMEAN Calculates the mean of groupings of an array.
%   This function calculates averages (ignoring NaNs) of groups of an array. This is useful, for
%   example, when deriving a null distribution for significance testing, where the null data array
%   must be averaged together in groupings of the same size as the real data. Thus, instead of
%   calculating the mean over an enire dimension of an array, this function calculates the mean over
%   smaller subsets of that dimension. It returns an array that is the same dimensionality as the
%   original array, but with greater than 1 elements in the specified dimension.
%
%   SYNTAX:
%   meanData = groupMean(inData, numPerGroup, dim)
%
%   OUTPUT:
%   meanData:           The averaged data array of the same dimensionality as the input data, but
%                       with "size(inData, dim)/numPerGroup" entries in dimension "dim". If the
%                       aforementioned division produces a remainder, this function removes entries
%                       along "dim" to produce equal-sized groupings (and to prevent bias from means
%                       over smaller sample sizes).
%
%   INPUTS:
%   inData:             The numerical input data array. This can be of any dimensionality, and any 
%                       "NaNs" in the data are accounted for during averaging by ignoring those
%                       entries.
%   
%   numPerGroup:        The scalar number of elements in dimension "dim" to be averaged over. For
%                       example, specifying "5" for "numPerGroup" and "3" for "dim" means that, over
%                       the 3rd dimension of the input data, every 5 entries are grouped together
%                       and averaged. 
%
%                       For convenience (with my data), this entry will also accomodate "scans" cell
%                       arrays, with each element of the cell representing a single subject and
%                       containing a vector of scans that are being analyzed. The function
%                       automatically calculates the total number of scans present and uses that as
%                       the number of elements per grouping.
%
%   dim:                The scalar dimension of the input data array over which to calculate
%                       averages.
%
%   Written by Josh Grooms on 20130627


%% Initialize
% Convert cell arrays of scans, if provided
if iscell(numPerGroup)
    numPerGroup = length(cat(2, numPerGroup{:}));
elseif ~isscalar(numPerGroup)
    error('Unknown input for parameter ''totalScans''. See documentation for help');
end

% Determine number of elements to remove over the desired dimension
numToRemove = rem(size(inData, dim), numPerGroup);

% Get the size of the input data array
szNull = size(inData);

% Reshape the input data array for generalized averaging
dimsVec = 1:ndims(inData);
dimsVec(dim) = 1; dimsVec(1) = dim;
inData = permute(inData, dimsVec);
inData = reshape(inData, [szNull(dim), prod(szNull(dimsVec(2:end)))]);

% Remove elements to create uniformly-sized groupings
if numToRemove ~= 0
    inData((end-numToRemove+1):end, :) = [];
    szNull(dim) = szNull(dim) - numToRemove;
end

% Allocate the output data array
szMean = szNull;
szMean(dim) = szMean(dim)./numPerGroup;
meanData = zeros(szMean(dim), prod(szNull(dimsVec(2:end))));


%% Calculate Groups Means
b = 1;
for a = 1:numPerGroup:szNull(dim)
    meanData(b, :) = nanmean(inData(a:(a+numPerGroup-1), :), 1);
        b = b + 1;
end

% Reshape the output array to match the input array
meanData = reshape(meanData, [szMean(dim), szNull(dimsVec(2:end))]);
meanData = permute(meanData, dimsVec);