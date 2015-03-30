function dataStruct = dataStructRegister(dataStruct, varargin)
%DATASTRUCTREGISTER Registers functional data to anatomical images.
%   This function coregisters functional to anatomical images using the SPM batch processing system.
%   Outputs are saved in a predefined location. References to these outputs are stored within the
%   human data structure.
%
%   SYNTAX:
%   dataStruct = dataStructRegister(dataStruct, 'PropertyName', PropertyValue...)
%   dataStruct = dataStructRegister(dataStruct, paramStruct.Registration)
%
%   OUTPUT:
%   dataStruct:         The human data structure with references to the registered mean and
%                       functional images.
%
%   INPUT:
%   dataStruct:         A human data structure.
%
%   OPTIONAL INPUT:
%   'CostFunction':     The function used to find registration parameters.
%                       DEFAULT: 'nmi'
%                       OPTIONS:
%                           'ecc' - Entropy Correlation Coefficient
%                           'mi'  - Mutual Information
%                           'ncc' - Normalized Cross Correlation
%                           'nmi' - Normalized Mutual Information
%
%   'FWHMSmoothing':    Size of the Gaussian being applying to histogram smoothing.
%                       DEFAULT: [7 7]
%
%   'Interpolation':    The image sampling method for registering to the anatomical space.
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
%   'Masking':          A boolean indicating whether or not to mask any given image using the rest
%                       of the scan's time series. If enabled, this functionality searches for any
%                       voxels that may fall outside of the original search field between images due
%                       to subject motion.
%                       DEFAULT: false
%
%   'OutputPrefix':     'The string to be prepended to output file names.
%                       DEFAULT: 'r'
%
%   'Separation':       The average separation (in millimeters) between sampled points in an image.
%                       This can be either a scalar or a vector. Inputting a vector provides coarse
%                       registration at first, followed by steps of increasingly finer registration.
%                       DEFAULT: [4 2]
%
%   'Tolerances':       The accuracy for each parameter, which dictates when the iterative
%                       registration process stops. 
%                       DEFAULT: [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001 0.001]
%
%   'Wrapping':         A three-element vector of booleans indicating the wrapping parameter
%                       settings during image reslicing.
%                       DEFAULT: [false false false]
%                       OPTIONS: (any and all trues are acceptable)
%                           [1 0 0] - Wrap in X direction
%                           [0 1 0] - Wrap in Y direction
%                           [0 0 1] - Wrap in Z direction
%
%   Written by Josh Grooms on 20130703


%% Initialize
% Initialize defaults & settings
if isstruct(varargin{1})
    assignInputs(varargin{1}, 'varsOnly');
else
    inStruct = struct(...
        'CostFunction', 'nmi',...
        'FWHMSmoothing', [7 7],...
        'Interpolation', 1,...
        'Masking', 0,...
        'OutputPrefix', 'r',...
        'Separation', [4 2],...
        'Tolerances', [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001 0.001],...
        'Wrapping', [0 0 0]);
    assignInputs(inStruct, varargin);
end

% Pull information from the data structure
imgFolder = dataStruct.Files.IMGFolder;
meanIMG = dataStruct.Files.IMG.Mean;
biasCorIMG = dataStruct.Files.IMG.BiasCorrected;
searchStr = dataStruct.Files.IMG.FunctionalStr;

% Get a list of the functional images & append ",1" to file paths
functionalFiles = get(fileData(imgFolder, 'ext', '.img', 'Search', searchStr), 'Path');
functionalFiles = cellfun(@(x) [x ',1'], functionalFiles, 'UniformOutput', false);

% Initialize SPM batch processing structure
matlabbatch{1}.spm.spatial.coreg.estwrite = struct(...
    'eoptions', struct(...
        'cost_fun', CostFunction,...
        'fwhm', FWHMSmoothing,...    
        'sep', Separation,...
        'tol', Tolerances),...
    'other', {functionalFiles},...  
    'ref', {{[biasCorIMG ',1']}},...
    'roptions', struct(...
        'interp', Interpolation,...
        'mask', Masking,...
        'prefix', OutputPrefix,...
        'wrap', Wrapping),...
    'source', {{[meanIMG ',1']}});


%% Coregister the Functional Data to Anatomical Images
% Run the SPM batch
spmOutput = spm_jobman('run', matlabbatch);

% Remove ",1" from the outputs
spmOutput{1}.rfiles = regexprep(spmOutput{1}.rfiles, ',1', '');

% Save the results
dataStruct.Files.IMG.Registered.Mean = spmOutput{1}.rfiles{1};
dataStruct.Files.IMG.Registered.FunctionalStr = [OutputPrefix searchStr];

