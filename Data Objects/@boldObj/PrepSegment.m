function PrepSegment(boldData, varargin)
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



%% Initialize
% Initialize defaults & settings
if nargin == 1
    assignInputs(boldData.Preprocessing.Parameters.Segmentation, 'varsOnly');
else
    inStruct = struct(...
        'BiasReg', 0.0001,...
        'BiasFWHM', 60,...
        'Cleanup', false,...
        'MaskImage', {{''}},...
        'NumGauss', [2 2 2 4],...
        'OutputCorrected', true,...
        'OutputCSF', [0 0 1],...
        'OutputGM', [0 0 1],...
        'OutputWM', [0 0 1],...
        'RegType', 'mni',...
        'SampleDistance', 3,...
        'WarpReg', true,...
        'WarpCutoff', 25);
    assignInputs(inStruct, varargin);
end

% Get needed folder locations
anatomicalData = boldData.Preprocessing.Files.IMG.Anatomical;
segmentsFolder = boldData.Preprocessing.Folders.Segments;

% Initialize SPM batch processing
spm_jobman('initcfg');



%% Run Anatomical Image Segmentation
% Run segmentation through SPM
wmFile = get(fileData(segmentsFolder, 'ext', '.nii', 'Search', 'white'), 'Path');
gmFile = get(fileData(segmentsFolder, 'ext', '.nii', 'Search', 'grey'), 'Path');
csfFile = get(fileData(segmentsFolder, 'ext', '.nii', 'Search', 'csf'), 'Path');

% Build the batch processing parameter structure
matlabbatch{1}.spm.spatial.preproc = struct(...
    'data', {anatomicalData},...
    'opts', struct(...
        'biasfwhm', BiasFWHM,...
        'biasreg', BiasReg,...
        'msk', {MaskImage},...
        'ngaus', [NumGauss],...
        'regtype', RegType,...
        'samp', SampleDistance,...
        'tpm', {{wmFile; gmFile; csfFile}}),...
    'output', struct(...
        'biascor', [OutputCorrected],...
        'cleanup', [Cleanup],...
        'CSF', [OutputCSF],...
        'GM', [OutputGM],...
        'WM', [OutputWM]));

% Run segmentation
spmOutput = spm_jobman('run', matlabbatch);

% Determine how many outputs there will be & pre-allocate data structure
numOutputs = sum([OutputCSF, OutputGM, OutputWM]);
boldData.Preprocessing.Files.IMG.Segments = cell(numOutputs, 1);

% Write the operations to a log file
if OutputCorrected
    boldData.Preprocessing.Files.IMG.BiasCorrected = spmOutput{1}.biascorr{1};
end
for a = 1:numOutputs
    fieldStr = ['c' num2str(a)];
    boldData.Preprocessing.Files.IMG.Segments(a) = {spmOutput{1}.(fieldStr){1}};
end