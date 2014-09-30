function PrepMotion(boldData)
% PREPMOTION - Estimate subject movements during the scan and correct for them by realigning images.
%
%   SYNTAX:
%   PrepMotion(boldData)
%   boldData.PrepMotion
%
%   INPUT:
%   boldData:                   BOLDOBJ
%                               A single BOLD data object undergoing preprocessing.
%
%   OPTIONAL INPUTS:
%   'FWHMSmooting':             INTEGER
%                               The size of the Gaussian kernel (in mm) that is used to smooth the images before
%                               estimating the realignment parameters.
%                               DEFAULT: 5
%
%   'EstimateInterpolation':    INTEGER
%                               The image sampling method used when estimating realignment parameters. Higher degree
%                               interpolations are better but are also much slower. This argument must be an integer
%                               "magic number" that corresponds with one of the options listed below.
%                               DEFAULT: 2
%                               OPTIONS:
%                                   0 - Nearest Neighbor (not recommended)
%                                   1 - Trilinear
%                                   2 - 2nd Degree B-Spline
%                                   3 - 3rd Degree B-Spline
%                                   .
%                                   .
%                                   .
%                                   7 - 7th Degree B-Spline
%
%   'EstimateWrapping':         [BOOLEAN, BOOLEAN, BOOLEAN]
%                               A Boolean vector specifying in which dimensions [X, Y, Z] the volumes are allowed to
%                               wrap through to the opposite bound. For example, MRI images can wrap through the phase
%                               encoding direction, resulting in an image where the subject's nose appears to poke into
%                               the back of their own head. Setting that direction to 'true' here can help produce more
%                               accurate estimates of the motion parameters.
%                               DEFAULT: [false, false, false]
%
%   'Masking'                   BOOLEAN
%   
%                               DEFAULT: true
%
%   'OutputPrefix':             STRING
%                               The string that will be prepended to the file names of images that have undergone this
%                               motion correction procedure.
%                               DEFAULT: 'r'
%
%   'Quality':                  DOUBLE
%                               A fractional value in the range [0, 1] representing the quality of the motion
%                               corrections. Higher values (to a maximum of 1) result in better quality realignment but
%                               require much more computing time. Lower quality values make the algorithm faster but may
%                               result in incomplete correction. 
%                               DEFAULT: 0.9
%
%   'RegisterToMean':           BOOLEAN
%                               A Boolean indicating whether or not images should be realigned with the mean image after
%                               realignment with the first scan of the sequence. For each individual scan, all images
%                               are always realigned with the first image, but setting this option to 'true' allows for
%                               each scan to be coregistered with the mean image of the series as well. However,
%                               coregistering with the mean image requires a second pass, which effectively doubles
%                               processing time, and may not improve results enough to warrant it.
%                               DEFAULT: true
%
%   'ResliceInterpolation':     INTEGER
%                               The image sampling method used when realigning the images. Higher degree interpolations
%                               are better but are also much slower. This argument must be an integer "magic number"
%                               that corresponds with one of the options listed below.
%                               DEFAULT: 2
%                               OPTIONS:
%                                   0 - Nearest Neighbor (not recommended)
%                                   1 - Trilinear
%                                   2 - 2nd Degree B-Spline
%                                   3 - 3rd Degree B-Spline
%                                   .
%                                   .
%                                   .
%                                   7 - 7th Degree B-Spline
%
%   'ResliceWrapping':          [BOOLEAN, BOOLEAN, BOOLEAN]
%                               A Boolean vector specifying in which dimensions [X, Y, Z] the volumes are allowed to
%                               wrap through to the opposite bound. For example, MRI images can wrap through the phase
%                               encoding direction, resulting in an image where the subject's nose appears to poke into
%                               the back of their own head. Setting that direction to 'true' here can help correct this
%                               kind of artifact. 
%                               DEFAULT: [false, false, false]
%
%   'Separation':               INTEGER
%                               The separation (in mm) between the sampled points in the reference image. Using smaller
%                               values for this argument produces better results, but requires much more computation
%                               time.
%                               DEFAULT: 4
%
%   'Weighting':                STRING
%                               A path string pointing to an image that is used to weight the contributions of
%                               individual voxels to subject motion. Weight values are proportional to the inverses of
%                               the standard deviations. Leaving this argument empty results in no weighting image being
%                               applied. 
%                               DEFAULT: ''

%% CHANGELOG
%   Written by Josh Grooms on 20140721
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.



%% Setup & Run Motion Correction
% Get the working data set & stage parameters
data = boldData.Preprocessing.WorkingData;
params = boldData.Preprocessing.Realignment;

% Initialize the SPM batch processing structure
matlabbatch{1}.spm.spatial.realign.estwrite = struct(...
    'data',             {{data.Functional}},...
    'eoptions', struct(...
        'fwhm',         params.FWHMSmoothing,...
        'interp',       params.Interpolation,...
        'quality',      params.Quality,...
        'rtm',          params.RegisterToMean,...
        'sep',          params.Separation,...
        'weight',       params.Weighting,...
        'wrap',         params.Wrapping),...
    'roptions', struct(...
        'interp',       params.Interpolation,...
        'mask',         params.Masking,...
        'prefix',       params.OutputPrefix,...
        'which',        [2, 1],...
        'wrap',         params.Wrapping));
    
% Run the motion correction procedure
spmOutput = spm_jobman('run', matlabbatch);



%% Store the Results
data.Functional = spmOutput{1}.sess.rfiles;
data.Mean = spmOutput{1}.rmean(1);
data.MotionParameters = spmOutput{1}.sess.rpfile{1};
boldData.Preprocessing.WorkingData = data;