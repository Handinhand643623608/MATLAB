function PrepSegment(boldData)
%PREPSEGMENT Segments MRI structural images into CSF, WM, and GM components.
%
%   SYNTAX:
%   PrepSegment(boldData)
%   PrepSegment(boldData, 'PropertyName', PropertyValue...)
%
%   INPUT:
%   boldData:               BOLDOBJ
%                           A BOLD human data object undergoing preprocessing.
%
%   OPTIONAL INPUTS:
%   'BiasReg':              DOUBLE
%                           Bias Regularization: a modeled correction for variations in image intensity caused by all MR
%                           scanners.
%                           DEFAULT: 0.0001
%                           OPTIONS:
%                               0       - No regularization
%                               0.00001 - Extremely light regularization
%                               0.0001  - Very light regularization
%                               0.001   - Light regularization
%                               0.01    - Medium regularization
%                               0.1     - Heavy regularization
%                               1       - Very heavy regularization
%                               10      - Extremely heavy regularization
%
%   'BiasFWHM':             INTEGER
%                           FWHM of Gaussian Bias Smoothness: an estimate of the smoothness of intensity non-uniformity
%                           (bias) in millimeters used for bias correction.
%                           DEFAULT: 60
%                           OPTIONS:
%                               30-150  - An integer between 30 & 150 (inclusive) in steps of 10 
%                                         only.
%                               
%   'Cleanup':              BOOLEAN
%                           A boolean dictating whether or not to clean up gray and white matter partitions using other
%                           segmentation results.
%                           WARNING: This can result in pieces of brain missing from data.
%                           DEFAULT: false
%
%   'MaskImage':            3D ARRAY
%                           An image to be used as a mask during segmentation.
%                           DEFAULT: {''}
%
%   'NumGauss':             [INTEGER, INTEGER, INTEGER, INTEGER]
%                           Number of Gaussians Per Tissue Type: the number of Gaussians used to represent the image
%                           intensity distribution per tissue type. This variable is given as a vector of length 4. Each
%                           element is an integer representing the quantity of Gaussians per tissue type in the
%                           following order: gray matter, white matter, CSF, everything else.
%                           DEFAULT: [2 2 2 4]
%
%   'OutputCorrected':      BOOLEAN
%                           A boolean indicating whether or not to output a bias-corrected version of the image.
%                           DEFAULT: true
%
%   'OutputCSF':            [BOOLEAN, BOOLEAN, BOOLEAN]
%                           A vector of booleans of length 3 indicating whether or not to output an image of CSF
%                           segmentation results. Each element of the vector represents the type(s) of image(s) to be
%                           saved. They are ordered as follows: modulated normalized, unmodulated normalized, native
%                           space.
%                           DEFAULT: [false false true]
%
%   'OutputGM':             [BOOLEAN, BOOLEAN, BOOLEAN]
%                           A vector of booleans of length 3 indicating whether or not to output an image of gray matter
%                           segmentation results. Each element of the vector represents the type(s) of image(s) to be
%                           saved. They are ordered as follows: modulated normalized, unmodulated normalized, native
%                           space.
%                           DEFAULT: [false false true]
%
%   'OutputWM':             [BOOLEAN, BOOLEAN, BOOLEAN]
%                           A vector of booleans of length 3 indicating whether or not to output an image of white
%                           matter segmentation results. Each element of the vector represents the type(s) of image(s)
%                           to be saved. They are ordered as follows: modulated normalized, unmodulated normalized,
%                           native space.
%                           DEFAULT: [false false true]
%
%   'SampleDistance':       DOUBLE
%                           Sampling Distance: the approximate distance between sampled points when estimating
%                           parameters for the bias correction model. Smaller values use more of the data, but slows
%                           down correction.
%                           DEFAULT: 3
%
%   'WarpReg':              DOUBLE
%                           Warping Regularization: a scalar governing the tradeoff between cost functions controlling
%                           the registration of segments to the data image. Higher values result in smoother
%                           deformations during registration.
%                           DEFAULT: 1
%
%   'WarpCutoff':           DOUBLE
%                           Warp Frequency Cutoff: a scalar lower bound on discrete cosine transform (DCT) bases used to
%                           describe segment warping during registration. Smaller values allow more detailed
%                           deformations, but greatly increase computational load.
%                           DEFAULT: 25



%% CHANGELOG
%   Written by Josh Grooms on 20130629
%       20140722:   Added the initial configuration of SPM batch processing to stop warnings being thrown.
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.



%% Initialize
% Get some needed parameters from the data object
data = boldData.Preprocessing.WorkingData;
params = mergestructs(...
    boldData.Preprocessing.DataPaths,...
    boldData.Preprocessing.Segmentation);    



%% Run Anatomical Image Segmentation
% Get the MNI segment probability maps
wmFile = searchdir(params.SegmentsFolder, 'white', 'Ext', '.nii');
gmFile = searchdir(params.SegmentsFolder, 'grey', 'Ext', '.nii');
csfFile = searchdir(params.SegmentsFolder, 'csf', 'Ext', '.nii');

% Build the batch processing parameter structure
matlabbatch{1}.spm.spatial.preproc = struct(...
    'data',             {data.Anatomical},...
    'opts', struct(...
        'biasfwhm',     params.BiasFWHM,...
        'biasreg',      params.BiasReg,...
        'msk',          {params.MaskImage},...
        'ngaus',        [params.NumGauss],...
        'regtype',      params.RegType,...
        'samp',         params.SampleDistance,...
        'tpm',          {{wmFile; gmFile; csfFile}}),...
    'output', struct(...
        'biascor',      [params.OutputCorrected],...
        'cleanup',      [params.Cleanup],...
        'CSF',          [params.OutputCSF],...
        'GM',           [params.OutputGM],...
        'WM',           [params.OutputWM]));
    
% Run segmentation
spmOutput = spm_jobman('run', matlabbatch);

% Get the bias corrected data
data.BiasCorrected = [];
if params.OutputCorrected
    data.BiasCorrected = spmOutput{1}.biascorr(1);
end

% Get the segmented data
numOutputs = sum([params.OutputCSF, params.OutputGM, params.OutputWM]);
data.Segments = cell(numOutputs, 1);
for a = 1:numOutputs
    fieldStr = ['c' num2str(a)];
    data.Segments(a) = spmOutput{1}.(fieldStr)(1);
end



%% Store File References in the Data Object
boldData.Preprocessing.WorkingData = data;