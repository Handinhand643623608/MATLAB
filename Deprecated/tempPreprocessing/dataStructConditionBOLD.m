function dataStruct = dataStructConditionBOLD(dataStruct, varargin)
%DATASTRUCTCONDITIONBOLD Conditions & finalizes BOLD data for analysis.
%   This function performs all of the final preprocessing and conditional of the BOLD data set prior
%   to it's release for other analyses. It blurs, filters, detrends, and regresses noise from the
%   BOLD data. 
%
%   SYNTAX:
%   dataStruct = dataStructConditionBOLD(dataStruct, 'PropertyName', PropertyValue...)
%   dataStruct = dataStructConditionBOLD(dataStruct, paramStruct.Conditioning)
%
%   OUTPUT:
%   dataStruct:             The finalized human BOLD data structure containing all functional scan
%                           data from a single scanning session.
%
%   INPUT:
%   dataStruct:             A human data structure after all other preprocessing steps have been
%                           completed.
%
%   OPTIONAL INPUTS:
%   'BlurMasks':            A boolean indicating whether or not to perform spatial Gaussian blurring
%                           on the segment masks (GM, WM, & CSF).
%                           DEFAULT: true
%
%   'CSFCutoff':            The cutoff value above which elements of the CSF probability image are
%                           considered to originate from CSF. This value is the threshold of the CSF
%                           data mask.
%                           DEFAULT: 0.2
%
%   'DetrendOrder':         The order of the polynomial used to detrend the functional data.
%                           DEFAULT: 2
%
%   'FilterData':           A boolean indicating whether or not to perform filtering on the time
%                           series data (BOLD and motion parameters).
%                           DEFAULT: true
%
%   'FilterLength':         The length of the FIR filter window (in data samples) used in filtering
%                           the time series data.
%                           DEFAULT: 25
%
%   'GMCutoff':             The cutoff value above which elements of the gray matter probability
%                           image are considered to originate from gray matter. This value is the
%                           threshold of the GM data mask.
%                           DEFAULT: 0.1
%
%   'MeanCutoff':           The cutoff value above which elements of the mean image are considered
%                           to originate from within the brain. This value is the threshold of the
%                           mean data mask.
%                           DEFAULT: 0.2
%   
%   'NumPCToRegress':       The number of principal components to regress from the functional data
%                           (as nuisance signals). This value is only used if "UsePCA" is set to
%                           true.
%                           DEFAULT: []
%                           WARNING: PCA nuisance regression has not yet been implemented.
%
%   'NumTRToRemove':        The integer number of TRs to remove from the beginning of each scanning 
%                           session. Typically, several TRs are removed in order to mitigate
%                           concerns about magnetization equilibrium effects. 
%                           DEFAULT: 0
%
%   'Passband':             A two-element vector dictating the [HIGHPASS LOWPASS] cutoff frequencies
%                           that all time series data will be filtered to. These cutoffs are
%                           specified in units of Hertz.
%                           DEFAULT: [0.01 0.08]
%
%   'PCAVarCutoff':         The variance cutoff value above which principal components are 
%                           considered to be nuisance signals. Such nuisance signals are likely to
%                           have larger variances, which means they will likely be among the first
%                           isolated principal components.
%                           DEFAULT: 0.0001
%   
%   'RegressCSF':           A boolean indicating whether or not to regress a CSF signal from the
%                           functional data. This signal is determined by averaging together voxels
%                           within the CSF segment mask that are likely to be CSF in origin (see
%                           "CSFCutoff" for information). It is then subtracted away from all other
%                           brain voxels.
%                           DEFAULT: true
%   
%   'RegressGlobal':        A boolean indicating whether or not to regress the global, or
%                           whole-brain, signal from the functional data. This signal is calculated
%                           as the average of all brain voxels across space. It is then subtracted
%                           from all brain voxels.
%                           DEFAULT: true
%
%   'SpatialBlurSigma':     The standard deviation (in voxels) of the Gaussian used to blur the
%                           data. This is a scalar value.
%                           DEFAULT: 2
%   
%   'SpatialBlurSize':      The size (in voxels) of the Gaussian used to the blur the data. This can
%                           be either a scalar (for a symmetric Gaussian) or a vector.
%                           DEFAULT: 3
%   
%   'UsePCA':               A boolean indicating whether or not to use principal component analysis
%                           (PCA) to isolate nuisance signals from the data. If true, nuisance
%                           signals for regression are generated by running PCA on the constructed
%                           nuisance signals (motion, global, white matter, CSF), which are then
%                           subtracted out of the functional data. This has the advantage of sparing
%                           low-variance effects that may be neurological in origin, but makes
%                           determining the source of the regressed signals difficult. 
%                           DEFAULT: false
%                           WARNING: PCA nuisance regression has not yet been implemented.
%   
%   'WMCutoff':             The cutoff value above which elements of the white matter probability 
%                           image are considered to originate from white matter. This value is the
%                           threshold of the WM data mask. 
%                           DEFAULT: 0.2
%
%   Written by Josh Grooms on 20130703


%% Initialize
if isstruct(varargin{1})
    assignInputs(varargin{1}, 'varsOnly');
else
    inStruct = struct(...
        'BlurMasks', true,...
        'CSFCutoff', 0.2,...
        'DetrendOrder', 2,...
        'FilterData', true,...
        'FilterLength', 25,...
        'GMCutoff', 0.1,...
        'MeanCutoff', 0.2,...
        'NumPCToRegress', NaN,...
        'NumTRToRemove', 0,...
        'Passband', [[0.01 0.08]],...
        'PCAVarCutoff', 0.0001,...
        'RegressCSF', true,...
        'RegressGlobal', true,...
        'SpatialBlurSigma', 2,...
        'SpatialBlurSize', 3,...
        'UsePCA', false,...
        'WMCutoff', 0.15);
    assignInputs(inStruct, varargin);
end

% Pull data from the data structure
boldData = dataStruct.Data.BOLD;
meanData = dataStruct.Data.Mean;
TR = dataStruct.Parameters.TR;

% Build a list of segmentation results
segmentStrs = {'GM', 'WM', 'CSF'};
for a = 1:length(segmentStrs)
    segmentData.(segmentStrs{a}) = dataStruct.Data.Segments.(segmentStrs{a});
end
    
% Import the motion parameter data & calculate the maximum subject movement
motionParamFile = get(fileData(dataStruct.Files.FunctionalFolder, 'ext', '.1D'), 'Path');
motionParams = importdata(motionParamFile);
maxDeviation = max(max(motionParams, [], 1) - min(motionParams, [], 1));


%% Condition the Non-Functional Scan Data
% Normalize the mean & segment data to between 0 and 1
meanData = (meanData - min(meanData(:)))./(max(meanData(:)) - min(meanData(:)));

% Blur the segments & normalize
blurFilterSpec = fspecial('gaussian', SpatialBlurSize, SpatialBlurSigma);
for a = 1:length(segmentStrs)
    currentSeg = segmentData.(segmentStrs{a});
    if BlurMasks
        currentSeg = imfilter(currentSeg, blurFilterSpec);
    end
    currentSeg = (currentSeg - min(currentSeg(:)))./(max(currentSeg(:)) - min(currentSeg(:)));
    segmentData.(segmentStrs{a}) = currentSeg;
end

% Scale the segments
idsMean = meanData > MeanCutoff;
segmentData.GM = idsMean.*(segmentData.GM > GMCutoff);
segmentData.WM = idsMean.*(1-segmentData.GM).*(segmentData.WM > WMCutoff);
segmentData.CSF = idsMean.*(1-(segmentData.GM+segmentData.WM)).*(segmentData.CSF > CSFCutoff);


%% Condition the Functional Data
% Remove TRs from the beginning of the time series
boldData = boldData(:, :, :, (NumTRToRemove+1):end);
szBOLD = size(boldData);
motionParams = motionParams((NumTRToRemove+1):end, :);

% Blur the functional images (try the fast method, then slice-wise if it fails)
try
    boldData = imfilter(boldData, blurFilterSpec);
catch
    for a = 1:szBOLD(3)
        for b = 1:szBOLD(4)
            boldData(:, :, a, b) = imfilter(boldData(:, :, a, b), blurFilterSpec);
        end
    end
end    

% Filter the functional data & motion parameters (try the fast method, then slice-wise if it fails)
if FilterData
    signalFilterSpec = fir1(FilterLength, Passband.*2.*TR);
    motionParams = filter(signalFilterSpec, 1, motionParams, [], 1);
    try
        boldData = filter(signalFilterSpec, 1, boldData, [], 4);
    catch
        for a = 1:szBOLD(3)
            boldData(:, :, a, :) = filter(signalFilterSpec, 1, boldData(:, :, a, :), [], 4);
        end
    end
    
    % Crop out the filter length from the beginning of all time series
    boldData = boldData(:, :, :, (FilterLength+1):end);
    szBOLD = size(boldData);
    motionParams = motionParams((FilterLength+1):end, :);
end

% Detrend the data voxel-wise
for a = 1:szBOLD(1)
    for b = 1:szBOLD(2)
        for c = 1:szBOLD(3)
            polyCoeffs = polyfit(1:szBOLD(4), squeeze(boldData(a, b, c, :)), DetrendOrder);
            boldData(a, b, c, :) = boldData(a, b, c, :) - reshape(polyval(polyCoeffs, 1:szBOLD(4)), 1, 1, 1, []);
        end
    end
end
            
% Z-Score the functional data (try the fast method, then slice-wise if it fails)
try
    boldData = zscore(boldData, [], 4);
catch
    for c = 1:szBOLD(3)
        boldData(:, :, a, :) = zscore(boldData(:, :, a, :), [], 4);
    end
end

% Regress nuisance parameters
nuisanceStrs = {'Motion', 'Global', 'WM', 'CSF'};
tempBOLD = reshape(boldData, [], szBOLD(4));
idsBrain = reshape(idsMean, [], 1);
for a = 1:length(nuisanceStrs)
    switch lower(nuisanceStrs{a})
        case 'motion'
            % Z-Score the transposed motion parameters & store
            nuisanceData.Motion = zscore(motionParams', [], 2);
        case 'global'
            % Average together BOLD voxels known to be in the brain, z-score, & store as global
            nuisanceData.Global =  mean(tempBOLD(idsBrain, :), 1);
            nuisanceData.Global =  zscore(nuisanceData.Global);
        otherwise
            % Average together WM & CSF data, z-score, & store
            tempData = reshape(segmentData.(nuisanceStrs{a}), [], 1);
            tempData = mean(tempBOLD(tempData > MeanCutoff, :), 1);
            nuisanceData.(nuisanceStrs{a}) = zscore(tempData);
    end
    % Regress each individual signal only from known brain voxels
    for b = 1:size(nuisanceData.(nuisanceStrs{a}), 1)
        tempBOLD(idsBrain, :) = bsxfun(@minus, tempBOLD(idsBrain, :), nuisanceData.(nuisanceStrs{a})(b, :));
    end
end
    
% Redo z-scoring on functional data
try
    boldData = zscore(boldData, [], 4);
catch
    for a = 1:szBOLD(3)
        boldData(:, :, a, :) = zscore(boldData(:, :, a, :), [], 4);
    end
end


%% Store the Data in the Data Structure
dataStruct.Data.Functional = boldData;
dataStruct.Data.Nuisance = nuisanceData;
dataStruct.Data.Mean = meanData;
dataStruct.Parameters.Quality.MaxDeviation = maxDeviation;
dataStruct.Data.Segments = segmentData;

