function initializeParameters(brainData, varargin)
%INITIALIZE
%
%
%   Written by Josh Grooms on 20131208


%% Initialize
% Capture input data & thresholds
if nargin > 1
    if ~isequal(size(varargin{1}), [91 109 91]) && ~isempty(varargin{1})
        error('Input data is of incorrect size. Only human data of dimensions [91 109 91] are currently supported');
    end
    functionalData = varargin{1};
    if nargin == 3
        threshData = varargin{2};
    else
        threshData = [];
    end
else
    functionalData = [];
    threshData = [];
end


%% Load the Appropriate Data Set & Rendering Parameters
% Determine which anatomical brain to load
switch brainData.AnatomicalBrain    
    case 'Colin' 
        % Load Colin Brain data sets
        load colinBrain; 
        volumeData = double(colinBrain); maskData = logical(colinMask);
        axLim = [109 91 91];
        dAspectRat = [1 1 1];
        isoVal = 0.55;
        strelRadius = 6;
    case 'MNI'
        % Load MNI Brain data sets
        load mniBrain; volumeData = double(mniBrain);
        maskData = [];
        axLim = [109 91 91];
        dAspectRat = [1 1 1];
        isoVal = 0.55;
        strelRadius = 2;
    case 'MNIHD'
        % Load high definition MNI Brain data sets
        load mniBrainHD; volumeData = double(mniBrain);
        maskData = [];
        axLim = [109 91 91];
        dAspectRat = [1.15 1.25 1];
        isoVal = 0.55;
        strelRadius = 1;
end

% Determine which permutation & model adjustment parameters are needed
switch brainData.SlicePlane
    case 'Transverse'
        permOrder = [1 2 3];
        rotAxis = [1 0 0];
        rotAlpha = 0;
    case 'Coronal'
        permOrder = [3 1 2];
        rotAxis = [1 0 0; 0 0 1];
        rotAlpha = [90, 90];
    case 'Sagittal'
        permOrder = [2 3 1];
        rotAxis = [0 0 1; 1 0 0];
        rotAlpha = [-90, -90];
end


%% Store the Data in the Data Object
brainData.IsoValue = isoVal;
brainData.Data = addfield(brainData.Data,...
    'Anatomical', volumeData,...
    'Functional', functionalData,...
    'Mask', maskData);
brainData.Parameters = addfield(brainData.Parameters,...
    'AxisLimits', axLim,...
    'DataAspectRatio', dAspectRat,...
    'PermutationOrder', permOrder,...
    'RotationAlpha', rotAlpha,...
    'RotationAxis', rotAxis,...
    'StrelRadius', strelRadius,...
    'Threshold', threshData);
    