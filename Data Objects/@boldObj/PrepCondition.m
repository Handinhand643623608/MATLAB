function PrepCondition(boldData, varargin)
%PREPCONDITION Conditions & finalizes BOLD data for analysis.
%   This function performs all of the final preprocessing and conditioning of the BOLD data set prior to it's release
%   for other analyses. It blurs, filters, detrends, and regresses noise from the BOLD data.
%
%   SYNTAX:
%   PrepCondition(boldData)
%   PrepCondition(boldData, 'PropertyName', PropertyValue...)
%
%   INPUT:
%   boldData:               BOLDOBJ
%                           A BOLD human data object after all other preprocessing steps have been completed.
%
%   OPTIONAL INPUTS:
%   'BlurMasks':            BOOLEAN
%                           A boolean indicating whether or not to perform spatial Gaussian blurring on the segment
%                           masks (GM, WM, & CSF).
%                           DEFAULT: true
%
%   'CSFCutoff':            DOUBLE
%                           The cutoff value above which elements of the CSF probability image are considered to
%                           originate from CSF. This value is the threshold of the CSF data mask.
%                           DEFAULT: 0.2
%
%   'DetrendOrder':         INTEGER
%                           The order of the polynomial used to detrend the functional data.
%                           DEFAULT: 2
%
%   'FilterData':           BOOLEAN
%                           A boolean indicating whether or not to perform filtering on the time series data (BOLD and
%                           motion parameters).
%                           DEFAULT: true
%
%   'FilterLength':         INTEGER
%                           The length of the FIR filter window (in seconds) used in filtering the time series data.
%                           DEFAULT: 45
%
%   'GMCutoff':             DOUBLE
%                           The cutoff value above which elements of the gray matter probability image are considered to
%                           originate from gray matter. This value is the threshold of the GM data mask.
%                           DEFAULT: 0.1
%
%   'MeanCutoff':           DOUBLE
%                           The cutoff value above which elements of the mean image are considered to originate from
%                           within the brain. This value is the threshold of the mean data mask.
%                           DEFAULT: 0.2
%   
%   'NumPCToRegress':       INTEGER
%                           The number of principal components to regress from the functional data (as nuisance
%                           signals). This value is only used if "UsePCA" is set to true.
%                           DEFAULT: []
%
%                           WARNING: PCA nuisance regression has not yet been implemented.
%
%   'NumTRToRemove':        INTEGER
%                           The integer number of TRs to remove from the beginning of each scanning session. Typically,
%                           several TRs are removed in order to mitigate concerns about magnetization equilibrium
%                           effects.
%                           DEFAULT: 0
%
%   'Passband':             [DOUBLE, DOUBLE]
%                           A two-element vector dictating the [HIGHPASS LOWPASS] cutoff frequencies that all time
%                           series data will be filtered to. These cutoffs are specified in units of Hertz.
%                           DEFAULT: [0.01 0.08]
%
%   'PCAVarCutoff':         DOUBLE
%                           The variance cutoff value above which principal components are considered to be nuisance
%                           signals. Such nuisance signals are likely to have larger variances, which means they will
%                           likely be among the first isolated principal components.
%                           DEFAULT: 0.0001
%   
%   'RegressCSF':           BOOLEAN
%                           A boolean indicating whether or not to regress a CSF signal from the functional data. This
%                           signal is determined by averaging together voxels within the CSF segment mask that are
%                           likely to be CSF in origin (see "CSFCutoff" for information). It is then subtracted away
%                           from all other brain voxels.
%                           DEFAULT: true
%   
%   'RegressGlobal':        BOOLEAN
%                           A boolean indicating whether or not to regress the global, or whole-brain, signal from the
%                           functional data. This signal is calculated as the average of all brain voxels across space.
%                           It is then subtracted from all brain voxels.
%                           DEFAULT: true
%
%   'SpatialBlurSigma':     INTEGER
%                           The standard deviation (in voxels) of the Gaussian used to blur the data. This is a scalar
%                           value.
%                           DEFAULT: 2
%   
%   'SpatialBlurSize':      INTEGER or [INTEGER, INTEGER]
%                           The size (in voxels) of the Gaussian used to the blur the data. This can be either a scalar
%                           (for a symmetric Gaussian) or a vector.
%                           DEFAULT: 3
%   
%   'UsePCA':               BOOLEAN
%                           A boolean indicating whether or not to use principal component analysis (PCA) to isolate
%                           nuisance signals from the data. If true, nuisance signals for regression are generated by
%                           running PCA on the constructed nuisance signals (motion, global, white matter, CSF), which
%                           are then subtracted out of the functional data. This has the advantage of sparing
%                           low-variance effects that may be neurological in origin, but makes determining the source of
%                           the regressed signals difficult.
%                           DEFAULT: false
%
%                           WARNING: PCA nuisance regression has not yet been implemented.
%
%   'UseZerPhaseFilter'     BOOLEAN
%                           A Boolean indicating whether or not to use a zero-phase distorting filter. Using this kind
%                           of filter means that no phase delay is imposed on the functional data set and thus no
%                           samples need to be cropped out.
%                           DEFAULT: true
%   
%   'WMCutoff':             DOUBLE
%                           The cutoff value above which elements of the white matter probability image are considered
%                           to originate from white matter. This value is the threshold of the WM data mask. 
%                           DEFAULT: 0.2



%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130708:   Bug fixes and optmizations to core functionality.
%       20130709:   Major bug fix to nuisance signal regressions being improperly done for WM and CSF signals.
%       20130710:   Complete re-write of nuisance signal regression section due to misunderstanding how this should be 
%                   done. Removed option input parameter structures.
%       20130711:   Updated to prevent memory errors during filtering when cropping out the filter length.
%       20130713:   Made this function much more robust to memory errors for large data sets.
%       20140612:   Updated the documentation of this method.
%       20140707:   Implemented zero-phase FIR filtering of time series data to prevent having to crop out a segment to
%                   account for phase shifts. Updated the documentation accordingly.
%       20140709:   Bug fix for compatibility with new MATFILE storage system.
%       20140720:   Updated some property names that changed in human data objects.

%% TODOS
% Immediate Todos
% - Replace old code here with calls to new methods that offer the same functionality



%% Initialize
if nargin == 1
    assignInputs(boldData.Preprocessing.Parameters.Conditioning, 'varsOnly');
else
    inStruct = struct(...
        'BlurMasks', true,...
        'CSFCutoff', 0.2,...
        'DetrendOrder', 2,...
        'FilterData', true,...
        'FilterLength', 45,...
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
        'UseZeroPhaseFilter', true,...
        'WMCutoff', 0.15);
    assignInputs(inStruct, varargin);
end

% Load the full object data set, because modifications to core data are occurring
boldData.LoadData();

% Pull data from the data structure
functionalData = ToArray(boldData);
origSzBOLD = size(functionalData);
meanData = boldData.Data.Mean;
TR = boldData.Acquisition.RepetitionTime/1000;

% Build a list of segmentation results
segmentStrs = {'GM', 'WM', 'CSF'};
for a = 1:length(segmentStrs)
    segmentData.(segmentStrs{a}) = boldData.Data.Segments.(segmentStrs{a});
end
    
% Import the motion parameter data & calculate the maximum subject movement
motionParamFile = get(fileData(boldData.Preprocessing.Folders.Functional, 'ext', '.1D'), 'Path');
motionParams = importdata(motionParamFile{1});
maxDeviation = max(max(motionParams, [], 1) - min(motionParams, [], 1));



%% Condition the Non-Functional Scan Data
% Normalize the mean & segment data to between 0 and 1
meanData = (meanData - min(meanData(:)))./(max(meanData(:)) - min(meanData(:)));
idsBrain = meanData > MeanCutoff;
idsBrainFlat = reshape(idsBrain, [], 1);

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
segmentData.GM = idsBrain.*(segmentData.GM > GMCutoff);
segmentData.WM = idsBrain.*(1-segmentData.GM).*(segmentData.WM > WMCutoff);
segmentData.CSF = idsBrain.*(1-(segmentData.GM+segmentData.WM)).*(segmentData.CSF > CSFCutoff);



%% Condition the Functional Data
% Remove TRs from the beginning of the time series
functionalData = functionalData(:, :, :, (NumTRToRemove+1):end);
szBOLD = size(functionalData);
motionParams = motionParams((NumTRToRemove+1):end, :);

% Blur the functional images
try % Blurring whole image first
    for a = 1:szBOLD(4)
        functionalData(:, :, :, a) = imfilter(functionalData(:, :, :, a), blurFilterSpec);
    end
catch % Memory errors, blur images slice-wise
    for a = 1:szBOLD(3)
        for b = 1:szBOLD(4)
            functionalData(:, :, a, b) = imfilter(functionalData(:, :, a, b), blurFilterSpec);
        end
    end
end    

% Flatten the functional data to two dimensions & discard empty space to facilitate further processing
functionalData = reshape(functionalData, [], szBOLD(4));
functionalData = functionalData(idsBrainFlat, :);
szBOLD = size(functionalData);

% Filter the functional data & motion parameters
if FilterData
    
    % Convert filter length in time to samples
    FilterLength = round(FilterLength./TR);
    
    % Set up the filter specifications & filter
    signalFilterSpec = fir1(FilterLength, Passband.*2.*TR);
    if istrue(UseZeroPhaseFilter)
        filterShift = 0;
        motionParams = filtfilt(signalFilterSpec, 1, motionParams);
        try % Filtering the whole time series at once
            functionalData = filtfilt(signalFilterSpec, 1, functionalData')';
        catch % Memory errors, filter voxel-wise
            for a = 1:szBOLD(1)
                functionalData(a, :) = filtfilt(signalFilterSpec, 1, functionalData(a, :));
            end
        end
    else
        filterShift = floor(FilterLength/2);
        motionParams = filter(signalFilterSpec, 1, motionParams, [], 1);
        try % Filtering the whole time series at once
            functionalData = filter(signalFilterSpec, 1, functionalData, [], 2);
        catch % Memory errors, filter voxel-wise
            for a = 1:szBOLD(1)
                functionalData(a, :) = filter(signalFilterSpec, 1, functionalData(a, :), [], 2);
            end
        end
    end
    
    % Crop out the filter length from the beginning of all time series
    if filterShift ~= 0
        try % Cropping whole time series
            % Try cropping the filter length
            functionalData(:, 1:filterShift) = [];
        catch % Memory errors, pack workspace data first
            % Pack the data to the hard disk & try again
            save('tempCondition.mat');
            clearvars -except functionalData;
            functionalData = functionalData(:, (filterShift+1):end);
            load('tempCondition.mat'); delete('tempCondition.mat');
        end
        szBOLD = size(functionalData);
        motionParams = motionParams((filterShift+1):end, :);
    end
end

% Detrend the data voxel-wise using only known in-brain data
for a = 1:size(functionalData, 1)
    polyCoeffs = polyfit(1:szBOLD(2), functionalData(a, :), DetrendOrder);
    functionalData(a, :) = functionalData(a, :) - polyval(polyCoeffs, 1:szBOLD(2));
end
            
% Z-Score the functional data (try the fast method, then voxel-wise if it fails)
try % Vectorized approach
    functionalData = zscore(functionalData, [], 2);
catch % Memory errors, z-score voxel-wise
    for a = 1:size(tempData, 1)
        functionalData(a, :) = zscore(functionalData(a, :), [], 2);
    end
end

% Regress nuisance parameters (order of strings is important)
if RegressGlobal
    if RegressCSF
        nuisanceStrs = {'Motion', 'Global', 'WM', 'CSF'};
    else
        nuisanceStrs = {'Motion', 'Global', 'WM'};
    end
else
    if RegressCSF
        nuisanceStrs = {'Motion', 'WM', 'CSF'};
    else
        nuisanceStrs = {'Motion', 'WM'};
    end
end
for a = 1:length(nuisanceStrs)
    % Gather the nuisance parameters into a structure
    switch lower(nuisanceStrs{a})
        case 'motion'
            nuisanceData.Motion = motionParams';
        case 'global'
            % Average together BOLD voxels known to be in the brain & store as global
            nuisanceData.Global =  mean(functionalData, 1);
        otherwise
            % Average together WM & CSF data & store
            tempSegData = reshape(segmentData.(nuisanceStrs{a}), [], 1);
            nuisanceData.(nuisanceStrs{a}) = mean(functionalData(tempSegData(idsBrainFlat) > MeanCutoff, :), 1);
    end
    
    for b = 1:size(nuisanceData.(nuisanceStrs{a}), 1)
        % Normalize the nuisance parameter to a vector of unit Euclidean length
        tempNuisance = nuisanceData.(nuisanceStrs{a})(b, :);
        tempNuisance = (tempNuisance - mean(tempNuisance))./norm(tempNuisance);
        tempNuisance = repmat(tempNuisance, szBOLD(1), 1);
        
        try % Vectorized fast method
            % Determine the scalar projection of functional data onto the nuisance data
            tempProj = dot(functionalData, tempNuisance, 2);
            tempProj = repmat(tempProj, 1, size(tempNuisance, 2));

            % Scale up the nuisance signal by projection length & regress from data series
            functionalData = functionalData - (tempProj.*tempNuisance);
        catch % Memory errors, regress signals voxel-wise
            for c = 1:szBOLD(1)
                tempProj = dot(functionalData(c, :), tempNuisance, 2);
                functionalData(c, :) = functionalData(c, :) - (tempProj.*tempNuisance);
            end
        end
    end
end
clear temp*
    
% Redo z-scoring on functional data
try
    functionalData = zscore(functionalData, [], 2);
catch
    for a = 1:szBOLD(1)
        functionalData(a, :) = zscore(functionalData(a, :), [], 2);
    end
end

% Zero out non-brain data & reshape the functional data into a volumetric array
allFunctionalData = zeros(length(idsBrainFlat), szBOLD(2));
allFunctionalData(idsBrainFlat, :) = functionalData;
clear functionalData;



%% Store the Data in the Data Structure
% Store data
boldData.Data.Functional = reshape(allFunctionalData, [origSzBOLD(1:3), szBOLD(2)]);
boldData.Data.Nuisance = nuisanceData;
boldData.Data.Mean = meanData;
boldData.Data.Segments = segmentData;

% Store preprocessing parameters not already in the object
boldData.Acquisition.MaxDeviation = maxDeviation;
boldData.Bandwidth = Passband;
boldData.IsGlobalRegressed = RegressGlobal;
boldData.IsFiltered = FilterData;
boldData.FilterShift = filterShift*TR;
boldData.IsZScored = true;
