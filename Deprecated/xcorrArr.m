function [ccArr, lags] = xcorrArr(x, y, varargin)
% XCORRARR - Cross-correlation of two arrays.
%   This function performs cross-correlation exactly as the native XCORR function does, but expands on built-in
%   functionality by allowing inputs of multidimensional arrays. This allows for rapid cross-correlation estimation
%   between many signals, instead of having to compute single vectors of correlations at a time using FOR loops (as
%   XCORR would require). The result is approximately a 1/3 reduction in computing time (computed using AF3-BOLD cross
%   correlation).
%
%   To use XCORRARR, input two arrays of arbitrary dimensionality and specify the dimension over which to estimate
%   cross-correlation. The two input arrays must be equal in size over the specified dimension, but may differ over the
%   other dimensions. The smaller of the two arrays (if not completely equal in size) is replicated to fill an array
%   equal in size to the other.
%
%   XCORRARR is useful when trying to calculate cross-correlations between a single signal and many signals (as in
%   cross-correlation between a single EEG time series and all fMRI voxel time series). In this example, the EEG signal
%   would be replicated to fill an array the same size as the fMRI data array, and correlation between the two would be
%   estimated over the specified time dimension at various signal lags, which can also be specified.
%
%   The lags used in this function refer to the delay between inputted signal arrays as correlation is estimated. A lag
%   of zero indicates that array elements of equal position are being compared. A negative lag indicates that earlier
%   (lower index along Dim) x elements are being compared to later (larger index along Dim) y elements. A positive lag
%   indicates that later (larger index along Dim) x elements are being compared to earlier (lower index along Dim) y
%   elements.
%
%   WARNING: This function requires large amounts of RAM to work with large data sets.
%
%   SYNTAX:
%   ccArr = xcorrArr(x, y)
%   ccArr = xcorrArr(x, y, 'PropertyName', PropertyValue...)
%   [ccArr, lags] = xcorrArr(...)
%   
%   OUTPUT:
%   ccArr:          An array of correlation estimates between x and y. This array is the same size as the larger of the 
%                   two input arrays, except over the user-specified Dim, where it is of size 2*MaxLags+1.
%
%   OPTIONAL OUTPUT: 
%   lags:           If called for, this is a vector of lags over which correlation was estimated. It is the same size as 
%                   ccArr over dimension Dim, and each elements represent the number of samples y was shifted relative
%                   to x during estimation.
%
%   INPUTS:
%   x:              An input data array of any size and dimensionality. Typically, this will be the  larger of the two 
%                   inputs. If not, this should be a vector (whose length spans Dim) or equal in size to y. The only
%                   real requirement for this input is that over dimension Dim, this array must be equal in size to y.
%
%   y:              A second input array. This input should either be equal in size to x or should be a vector whose 
%                   length spans Dim, unless x is the vector (in which case this input may be any size). Over Dim, the
%                   size of this array must be equal x.
%
%   OPTIONAL INPUTS:
%   'Dim':          A scalar indicating the dimension over which to estimate correlations.
%                   DEFAULT: 2
%
%   'GPU':          A Boolean indicating whether or not to use the computer's GPU in the calculations. If a compatible
%                   GPU is available, this can greatly speed up the computations for this function, which can be quite
%                   intensive.
%                   DEFAULT: 'off'
%
%   'MaxLag':       A scalar indicating the maximum of the range of data lags that are outputted. This is specified in 
%                   data samples (number of array elements) and not time or any other unit. 
%                   DEFAULT: size(x, Dim) - 1
%
%   'Scale':        A string indicating how output correlations should be scaled or normalized. This parameter is the 
%                   same as SCALEOPT from the native function XCORR.
%                   DEFAULT: 'coeff'
%                   OPTIONS:
%                       'biased'    - scale by 1/size(x, Dim)
%                       'coeff'     - scales output so that auto-correlations are 1
%                       'none'      - no scaling
%                       'unbiased'  - scales output by 1/(size(x, Dim)-abs(lags))
%
%   See also XCORR, XCOV, CORRCOEF

%% CHANGELOG
%   Written by Josh Grooms on 20130709
%       20131126:   Implemented GPU processing for improved speed & updated documentation accordingly.
%       20141007:   Moved an error check for input array sizes to an earlier position in the function. Implemented the
%                   ability to perform autocorrelations on arrays if an empty second input is provided.

DEPRECATED ccorr



%% Initialize
inStruct = struct(...
    'Dim', 2,...
    'GPU', 'off',...
    'MaxLag', [],...
    'ScaleOpt', 'coeff');
assignInputs(inStruct, varargin,...
    'compatibility', {'Dim', 'dimension', [];
                      'MaxLag', 'lag', 'maxlags';
                      'ScaleOpt', 'normalize', 'scale'});

% Deal with missing inputs
if isempty(y); y = x; end
                  
% Move calculations to the GPU for maximum speed, if called for
if istrue(GPU)
    reset(gpuDevice);
    x = gpuArray(x);
    y = gpuArray(y);
end

% Compute the default MaxLags value & lags vector
if isempty(MaxLag); MaxLag = size(x, Dim) - 1; end
lags = -MaxLag:MaxLag;

% Get the size of the input arrays & check for sizing errors
szx = size(x);
szy = size(y);
if szx(Dim) ~= szy(Dim)
    error('Arrays must be the same size over the dimension being correlated.');
end

% Permute the arrays so that correlation dimension is the last
permOrder = 1:ndims(x); permOrder(Dim) = ndims(x); permOrder(end) = Dim;
x = permute(x, permOrder);
szPermx = size(x);
y = permute(y, permOrder);
szPermy = size(y);

% Flatten the arrays to two dimensions to ease computation
flatx = reshape(x, [], szx(Dim));
szFlatx = size(flatx, 1);
flaty = reshape(y, [], szy(Dim));
szFlaty = size(flaty, 1);

% Make sure input arrays are the same size
szCheck = [szFlatx(1) szFlaty(1)] == min(szFlatx(1), szFlaty(1));
if ~all(szCheck)
    tempData = {flatx, flaty};
    tempSize = cellfun(@size, tempData, 'UniformOutput', false);
    tempData{szCheck} = repmat(tempData{szCheck}, tempSize{~szCheck}(1)/tempSize{szCheck}(1), 1);
    flatx = tempData{1};
    flaty = tempData{2};
    szFlat = size(flatx);
end
clear temp*



%% Compute Cross Correlation
% Fourier transform the data (for speed of calculation)
X = fft(flatx, 2^nextpow2(2*szx(Dim)-1), 2);
Y = fft(flaty, 2^nextpow2(2*szy(Dim)-1), 2);

% Compute cross-correlation in frequency domain, then transform back
ccArr = real(ifft(X.*conj(Y), [], 2));



%% Discard Unwanted Lags & Scale the Data
% Discard unwanted lags
ccArr = [ccArr(:, end-MaxLag+1:end) ccArr(:, 1:MaxLag+1)];

% Scale the data
switch lower(ScaleOpt)
    case 'biased'
        ccArr = ccArr./size(ccArr, 2);
        
    case 'coeff'
        scale = sqrt(sum(abs(flatx).^2, 2).*sum(abs(flaty).^2, 2));
        scale = repmat(scale, 1, size(ccArr, 2));
        ccArr = ccArr./scale;
        
    case 'unbiased'
        tempScale = size(x, Dim) - abs(lags); tempScale(tempScale <= 0) = 1;
        tempScale = repmat(tempScale, size(ccArr, 1), 1);
        ccArr = ccArr./tempScale;
end



%% Reshape & Unpermute the Data
tempSize = {szPermx, szPermy};
if ~all(szCheck)
    ccArr = reshape(ccArr, [tempSize{~szCheck}(1:end-1), length(lags)]);
else
    ccArr = reshape(ccArr, [szPermx(1:end-1), length(lags)]);
end
clear temp*
ccArr = permute(ccArr, permOrder);

% Gather results from the GPU, if necessary
if istrue(GPU)
    ccArr = gather(ccArr);
end