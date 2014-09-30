function PrepRegister(boldData)
% PREPREGISTER - Registers functional data to anatomical images.
%   This function coregisters functional to anatomical images using the SPM batch processing system. Outputs are saved
%   in a predefined location. References to these outputs are stored within the human data structure.
%
%   SYNTAX:
%   PrepRegister(boldData)
%   boldData.PrepRegister
%
%   INPUT:
%   boldData:           BOLDOBJ
%                       A single BOLD data object undergoing preprocessing.
%
%   PARAMETER DEFITIONS:
%   'CostFunction':     STRING
%                       The function used to find registration parameters.
%                       DEFAULT: 'nmi'
%                       OPTIONS:
%                           'ecc' - Entropy Correlation Coefficient
%                           'mi'  - Mutual Information
%                           'ncc' - Normalized Cross Correlation
%                           'nmi' - Normalized Mutual Information
%
%   'FWHMSmoothing':    [INTEGER, INTEGER]
%                       Size of the Gaussian being applying to histogram smoothing.
%                       DEFAULT: [7 7]
%
%   'Interpolation':    INTEGER
%                       The image sampling method for registering to the anatomical space.
%                       DEFAULT: 1
%                       OPTIONS:
%                           0 - Nearest Neighbor (not recommended)
%                           1 - Trilinear
%                           2 - 2nd Degree B-Spline
%                           3 - 3rd Degree B-Spline
%                           .
%                           .
%                           .
%                           7 - 7th Degree B-Spline
%
%   'Masking':          BOOLEAN
%                       A boolean indicating whether or not to mask any given image using the rest of the scan's time
%                       series. If enabled, this functionality searches for any voxels that may fall outside of the
%                       original search field between images due to subject motion.
%                       DEFAULT: false
%
%   'OutputPrefix':     STRING
%                       The string to be prepended to output file names.
%                       DEFAULT: 'r'
%
%   'Separation':       DOUBLE or [DOUBLE, DOUBLE]
%                       The average separation (in millimeters) between sampled points in an image. This can be either a
%                       scalar or a vector. Inputting a vector provides coarse registration at first, followed by steps
%                       of increasingly finer registration.
%                       DEFAULT: [4 2]
%
%   'Tolerances':       DOUBLE VECTOR
%                       The accuracy for each parameter, which dictates when the iterative registration process stops.
%                       DEFAULT: [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001 0.001]
%
%   'Wrapping':         [BOOLEAN, BOOLEAN, BOOLEAN]
%                       A three-element vector of booleans indicating the wrapping parameter settings during image
%                       reslicing.
%                       DEFAULT: [false false false]
%                       OPTIONS: (any and all trues are acceptable)
%                           [1 0 0] - Wrap in X direction
%                           [0 1 0] - Wrap in Y direction
%                           [0 0 1] - Wrap in Z direction

%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130708:   Bug fix for SPM parameter matrix typo.
%       20140721:   Changed the way IMG files were being identified here and in other related SPM preprocessing
%                   functions. File references are now passed along from stage to stage in the pipeline, eliminating the
%                   need for searching through directories.
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.



%% Initialize
% Get the working data set & stage parameters
params = boldData.Preprocessing.Registration;
data = boldData.Preprocessing.WorkingData;

% Initialize SPM batch processing structure
matlabbatch{1}.spm.spatial.coreg.estwrite = struct(...
    'eoptions', struct(...
        'cost_fun',     params.CostFunction,...
        'fwhm',         params.FWHMSmoothing,...    
        'sep',          params.Separation,...
        'tol',          params.Tolerances),...
    'other',            {data.Functional},...
    'ref',              {data.BiasCorrected},...
    'roptions', struct(...
        'interp',       params.Interpolation,...
        'mask',         params.Masking,...
        'prefix',       params.OutputPrefix,...
        'wrap',         params.Wrapping),...
    'source',           {data.Mean});

% Run the SPM batch
spmOutput = spm_jobman('run', matlabbatch);



%% Store the Results
data.Mean = spmOutput{1}.rfiles(1);
data.Functional = spmOutput{1}.rfiles(2:end);
boldData.Preprocessing.WorkingData = data;





% 
% % Initialize defaults & settings
% if nargin == 1
%     assignInputs(boldData.Preprocessing.Parameters.Registration, 'varsOnly');
% else
%     inStruct = struct(...
%         'CostFunction', 'nmi',...
%         'FWHMSmoothing', [7 7],...
%         'Interpolation', 1,...
%         'Masking', 0,...
%         'OutputPrefix', 'r',...
%         'Separation', [4 2],...
%         'Tolerances', [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001 0.001],...
%         'Wrapping', [0 0 0]);
%     assignInputs(inStruct, varargin);
% end
% 
% % Pull information from the data structure
% functionalIMG = boldData.Preprocessing.Files.IMG.Functional;
% meanIMG = boldData.Preprocessing.Files.IMG.Mean;
% biasCorIMG = boldData.Preprocessing.Files.IMG.BiasCorrected;
% 
% % Initialize SPM batch processing structure
% matlabbatch{1}.spm.spatial.coreg.estwrite = struct(...
%     'eoptions', struct(...
%         'cost_fun', CostFunction,...
%         'fwhm', FWHMSmoothing,...    
%         'sep', Separation,...
%         'tol', Tolerances),...
%     'other', {functionalIMG},...
%     'ref', {{[biasCorIMG ',1']}},...
%     'roptions', struct(...
%         'interp', Interpolation,...
%         'mask', Masking,...
%         'prefix', OutputPrefix,...
%         'wrap', Wrapping),...
%     'source', {{meanIMG}});
% 
% 
% 
% %% Coregister the Functional Data to Anatomical Images
% % Run the SPM batch
% spmOutput = spm_jobman('run', matlabbatch);
% 
% % Save the results
% boldData.Preprocessing.Files.IMG.Mean = spmOutput{1}.rfiles{1};
% boldData.Preprocessing.Files.IMG.Functional = spmOutput{1}.rfiles(2:end);
% 

