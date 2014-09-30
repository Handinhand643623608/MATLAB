function PrepNormalize(boldData)
% PREPNORMALIZE - Normalizes BOLD functional images to MNI space.
%
%   SYNTAX:
%   PrepNormalize(boldData)
%   PrepNormalize(boldData, 'PropertyName', PropertyValue...)
%
%   INPUT:
%   boldData:               BOLDOBJ
%                           A single BOLD data object undergoing preprocessing.
%
%   OPTIONAL INPUTS:
%   'AmtRegularization':    INTEGER
%                           The amount of regularization for the nonlinear part of spatial normalization.
%                           DEFAULT: 1
%
%   'BoundingBox':          [ 2x3 DOUBLE ]
%                           The volume relative to the anterior commissure that is to be written.
%                           DEFAULT: [-78, -112, -50; 78, 76, 85]
%                               
%   
%   'DCTCutoff':            DOUBLE
%                           The scalar lower bound on discrete cosine transform (DCT) bases used to describe image
%                           warping during normalization. Smaller values allow for more detailed deformations but
%                           greatly increase the computational load.
%                           DEFAULT: 25
%   
%   'Interpolation':        INTEGER
%                           The image sampling method used when realigning the images. Higher degree interpolations
%                           are better but are also much slower. This argument must be an integer "magic number"
%                           that corresponds with one of the options listed below.
%                           DEFAULT: 2
%                           OPTIONS:
%                               0 - Nearest Neighbor (not recommended)
%                               1 - Trilinear
%                               2 - 2nd Degree B-Spline
%                               3 - 3rd Degree B-Spline
%                               .
%                               .
%                               .
%                               7 - 7th Degree B-Spline
%
%   'Masking':
%
%
%   'NumIterations':
%
%   'OutputPrefix':         STRING
%                           The string that will be prepended to the file names of images that have undergone this slice
%                           timing correction procedure.
%                           DEFAULT: 'w'
%
%   'Preservation':
%
%
%   
%   'Regularization':       STRING
%       
%                           DEFAULT: 'mni'
%
%   'SourceSmoothing':      INTEGER
%                           The amount of smoothing to apply to the source (i.e. functional) images.
%                           DEFAULT: 8
%   
%   'TemplateImage':        
%   
%   'TemplateSmoothing':    INTEGER
%                           The amount of smoothing to apply to the template image.
%                           DEFAULT: 0
%
%   'TemplateWeightImage':  { STRINGS }
%                           A reference to a weighting file used to mask the functional data.
%                           DEFAULT: {''}
%
%   'VoxelSize':            [DOUBLE, DOUBLE, DOUBLE]
%                           The desired size (in millimeters formatted as [X, Y, Z]) of all voxels in the normalized
%                           functional data array.
%                           DEFAULT: [2, 2, 2]
%
%   'Wrapping':             [BOOLEAN, BOOLEAN, BOOLEAN]
%                           A Boolean vector specifying in which dimensions [X, Y, Z] the volumes are allowed to wrap
%                           through to the opposite bound. For example, MRI images can wrap through the phase encoding
%                           direction, resulting in an image where the subject's nose appears to poke into the back of
%                           their own head. Setting that direction to 'true' here can help correct this kind of
%                           artifact.
%                           DEFAULT: [false, false, false]
%   

%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20140721:   Changed the way IMG files were being identified here and in other related SPM preprocessing
%                   functions. File references are now passed along from stage to stage in the pipeline, eliminating the
%                   need for searching through directories. Removed the separate template image parameter from this
%                   preprocessing stage, since the MNI brain was the only one ever used and there's an existing
%                   reference to it elsewhere.
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.

%% TODOS
% Immediate Todos
% - Complete documentation for this method.



%% Initialize
% Get the working data set & stage parameters
data = boldData.Preprocessing.WorkingData;
params = mergestructs(...
    boldData.Preprocessing.DataPaths,...
    boldData.Preprocessing.Normalization);

% SPM sometimes requires data file references to be appended with a session number


allImages = cat(1, data.BiasCorrected, data.Mean, data.Segments, data.Functional);
% allImages = cellfun(@(x) ([x ',1']), allImages, 'UniformOutput', false);
mniTemplate = {[params.MNIBrainTemplate ',1']};

% Initialize the SPM normalization batch processing
normBatch{1}.spm.spatial.normalise.estwrite = struct(...
    'eoptions', struct(...
        'cutoff',           params.DCTCutoff,...
        'nits',             params.NumIterations,...
        'reg',              params.AmtRegularization,...
        'regtype',          params.Regularization,...
        'smosrc',           params.SourceSmoothing,...    
        'smoref',           params.TemplateSmoothing,...
        'template',         {mniTemplate},...
        'weight',           params.TemplateWeightImage),...
    'roptions', struct(...
        'bb',               params.BoundingBox,...
        'interp',           params.Interpolation,...
        'prefix',           'r',...
        'preserve',         params.Preservation,...
        'vox',              params.VoxelSize,...
        'wrap',             params.Wrapping),...
    'subj', struct(...
        'resample',         {allImages},...
        'source',           {data.BiasCorrected},...
        'wtsrc',            ''));
    
% Initialize the SPM coregistration batch processing
regBatch{1}.spm.spatial.coreg.write = struct(...
    'ref',                  {mniTemplate},...
    'roptions', struct(...
        'interp',           params.Interpolation,...
        'mask',             params.Masking,...    
        'prefix',           params.OutputPrefix,...
        'wrap',             params.Wrapping),...
    'source',               []);                    % <-- Filled in with results of normalization



%% Run SPM Normalization
% Normalize to the template image
normOutput = spm_jobman('run', normBatch);
regBatch{1}.spm.spatial.coreg.write.source = normOutput{1}.files;
regOutput = spm_jobman('run', regBatch);



%% Store the Results
data.BiasCorrected = regOutput{1}.rfiles(1);
data.Mean = regOutput{1}.rfiles(2);
data.Segments = regOutput{1}.rfiles(3:5);
data.Functional = regOutput{1}.rfiles(6:end);
boldData.Preprocessing.WorkingData = data;