function paramStruct = PrepParameters
%PARAMETERS Returns a parameter structure with default values for BOLD data preprocessing.
%   This function exists only to return a default parameter structure that governs the entire BOLD data object usage.
%   The fields and substructures within the output constitute all possible user input accepted during the instantiation
%   of a BOLD object.
%
%   SYNTAX:
%   paramStruct = Parameters(boldObj)
%
%   OUTPUT:
%   paramStruct:    STRUCT
%                   This is a structure whose fields and substructure fields constitute the only available user input to 
%                   the BOLD data object. Default values are filled in. Change any of these values as needed and input
%                   the structure back into BOLDOBJ or any compatible analysis methods using the STRUCT2VAR function. 
%                   
%                   EXAMPLE:
%                       paramStruct = parameters(boldObj);
%                       % Change field values as needed
%                       .
%                       .
%                       .
%                       boldData = boldObj(paramStruct);
%
%   INPUTS:
%   boldObj:        The input to this function must always be "boldObj" (without quotes) and nothing else. This is so 
%                   MATLAB knows which method to call to return the correct parameter structure. "boldObj" is the class
%                   name of the BOLD data object.

%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130711:   Updated to include a "General" section with frequenctly updated parameters.
%       20130730:   Implemented ability to convert object into old human_data structures before saving.
%       20140612:   Removed the switch/case originally intended for multiple parameter structures. These were never
%                   implemented and I doubt they ever will be. Updated the documentation accordingly.
%       20140707:   Added in the option to use zero-phase FIR filtering during signal conditioning to prevent having to
%                   crop out sections of time series.
%       20140720:   Added in the option to turn off slice-timing corrections. This shouldn't be used on data sets with
%                   fast TRs.
%       20140929:   Completely reorganized the parameter structure and this container file so that it's easier to parse.
%                   Implemented a number of new options that toggle different stages of the preprocessing pipeline on or
%                   off.

%% TODOS
% Immediate
%   - Parameter verification before preprocessing starts



%% General Preprocessing Parameters (Will Frequently Change)
% Provide input & output data paths
paramStruct.DataPaths = struct(...
    'MNIBrainTemplate',         'C:/Users/jgrooms/Dropbox/Globals/MNI/template/T1.nii',...  % The path to the MNI brain template image
    'MNIFolder',                'C:/Users/jgrooms/Dropbox/Globals/MNI',...                  % 
    'OutputPath',               'C:/Users/jgrooms/Desktop/Data Sets/Data Objects/BOLD',...  % Choose where preprocessed data should be saved
    'RawDataPath',              'S:/Josh/Data/Raw',...                                      % Specify the top-level raw data path (where each subject data folder is)
    'SegmentsFolder',           'C:/Users/jgrooms/Dropbox/Globals/MNI/segments');           % Specify where MNI segment maps are stored

% Provide data folder signatures that uniquely identify subject- & scan-specific data (use REGEXP metacharacters if necessary)
paramStruct.DataFolderIDs = struct(...
    'AnatomicalFolderID',       't1_MPRAGE_',...                                    % Provide a naming prototype that identifies each subject's structural scan
    'FunctionalFolderID',       'ep2d_.*_Rest_\d',...                               % Provide a naming prototype that identifies all functional data folders inside subject folders
    'SubjectFolderID',          '1..A');                                            % Provide a naming prototype that identifies all subject data folders

% Indicate which scans should be preprocessed
scansToProcess = {[1, 2], [1, 2], [1, 2], [1, 2], [], [], [1, 2], [1, 2]};
paramStruct.DataSelection = struct(...
    'ScanState',                'RS',...                                            % Provide the task that subjects performed during the scans (has no impact on preprocessing)
    'ScansToProcess',           {scansToProcess},...                                % List which scans (per subject) should be preprocessed
    'SubjectsToProcess',        [1:4, 7, 8]);                                       % List which subjects should be preprocessed

% Choose which preprocessing stages will be utilized
paramStruct.StageSelection = struct(...
    'UseCoregistration',        true,...                                            % Coregister functional with anatomical images
    'UseMotionCorrection',      true,...                                            % Correct minor subject movements during imaging
    'UseNormalization',         true,...                                            % Normalize functional images to MNI space
    'UseNuisanceRegression',    true,...
    'UseSignalConditioning',    true,...                                            % Use a prescribed sequence of image detrending, filtering, & nuisance correction4
    'UseSliceTimingCorrection', true,...                                            % Correct time delays arising from imaging adjacent brain slices at different times
    'UseSpatialBlurring',       true,...
    'UseTemporalFiltering',     true);



%% Parameters for the Final Stages of Preprocessing (Might Change Occasionally)
% These tasks are performed after all of the typical SPM preprocessing stages through custom-written routines

% Control the spatial blurring of functional & segment images
paramStruct.SpatialBlurring = struct(...
    'ApplyToMasks',             true,...                                            % Should structural segments also be blurred?
    'Sigma',                    2,...                                               % The standard deviation of the Gaussian used to blur images (in voxels)
    'Size',                     3);                                                 % The size of the Gaussian used to blur images (in voxels)

% Specify how to threshold segment images for use as masks
paramStruct.SegmentThresholds = struct(...
    'CSFCutoff',                0.2,...                                             % The cutoff probability above which normalized segment voxels are considered to be CSF
    'GrayMatterCutoff',         0.1,...                                             % The cutoff probability above which normalized segment voxels are considered to be gray matter
    'MeanImageCutoff',          0.2,...                                             % The cutoff probability above which mean image voxels are considered to be brain tissue
    'WhiteMatterCutoff',        0.15);                                              % The cutoff probability above which normalized segment voxels are considered to be white matter

% Specify what kind of signals to linearly regress from functional time series
paramStruct.NuisanceRegression = struct(...
    'DetrendOrder',             2,...                                               % Specify the order of the polynomial used to regress ultra-low-frequency drift artifacts
    'RegressCSF',               false,...                                           % Should the average CSF signal be regressed from functional time series?
    'RegressGlobal',            false,...                                           % Should the global (i.e. grand mean) signal be regressed from functional time series?
    'RegressWhiteMatter',       false);                                             % Should the average white matter signal be regressed from functional time series?

% Specify how many TRs to remove from each data set
paramStruct.SignalCropping = struct(...
    'NumTimePointsToRemove',    1);                                                 % The number of TRs to remove from the beginning of each image series

% Specify parameters for voxel signal filtering
paramStruct.TemporalFiltering = struct(...
    'Passband',                 [0.01 0.08],...                                     % The passband of the filter (in Hertz)
    'Window',                   'gaussian',...
    'WindowLength',             45);                                                % The length of the filter window (in seconds)                                       



%% Specific Parameters for Each Preprocessing Stage (Unlikely to Change)
% Nearly all of these parameters are derived directly from SPM's batch processing system

% Control segmentation of structural scans
paramStruct.Segmentation = struct(...
    'BiasReg',                  0.0001,...
    'BiasFWHM',                 60,...
    'Cleanup',                  false,...
    'MaskImage',                {{''}},...
    'NumGauss',                 [2 2 2 4],...
    'OutputCorrected',          true,...
    'OutputCSF',                [0 0 1],...
    'OutputGM',                 [0 0 1],...
    'OutputWM',                 [0 0 1],...
    'RegType',                  'mni',...
    'SampleDistance',           3,...
    'WarpReg',                  true,...
    'WarpCutoff',               25);

paramStruct.Realignment = struct(...
    'FWHMSmoothing',            5,...
    'Interpolation',            2,...
    'Masking',                  true,...
    'OutputPrefix',             'r',...
    'Quality',                  0.9,...
    'RegisterToMean',           true,...
    'Separation',               4,...
    'Weighting',                '',...
    'Wrapping',                 [0 0 0]);

% Control coregistration of functional to anatomical images
paramStruct.Registration = struct(...
    'CostFunction',             'nmi',...
    'FWHMSmoothing',            [7 7],...
    'Interpolation',            1,...
    'Masking',                  false,...
    'OutputPrefix',             'r',...
    'Separation',               [4 2],...
    'Tolerances',               [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001 0.001],...
    'Wrapping',                 [0 0 0]);
    
% Control normalization of functional images to MNI spatial coordinates
paramStruct.Normalization = struct(...
    'AmtRegularization',        1,...
    'BoundingBox',              [-78 -112 -50; 78 76 85],...
    'DCTCutoff',                25,...
    'Interpolation',            1,...
    'Masking',                  false,...
    'NormPrefix',               'w',...
    'NumIterations',            16,...
    'Preservation',             0,...
    'RegPrefix',                'r',...
    'Regularization',           'mni',...
    'SourceSmoothing',          8,...
    'TemplateImage',            [],...
    'TemplateSmoothing',        0,...
    'TemplateWeightImage',      {''},...
    'VoxelSize',                [2 2 2],...
    'Wrapping',                 [0 0 0]);





%% Select & Return the Parameter Structure for Data Preprocessing

% 
% 
% paramStruct = struct(...
%     'General', struct(...
%         'ConvertToStructure', false,...
%         'LargeData', false,...
%         'OutputPath', 'E:\Graduate Studies\Lab Work\Data Sets\Raw Data\SchumacherData',...
%         'Scans', {{[1]}},...
%         'ScanState', 'RS',...
%         'Subjects', 1,...
%         'UseSliceTimingCorrection', false),...
%     'Initialization', struct(...
%         'AnatomicalFolderStr', 't1_MPRAGE_',...
%         'DataPath', 'E:\Graduate Studies\Lab Work\Data Sets\Raw Data\SchumacherData',...
%         'FunctionalFolderStr', 'fMRI_\d_\d\d',...
%         'IMGFolderStr', 'IMG',...
%         'MNIBrain', 'C:\Users\Josh\Dropbox\Globals\MNI\template\T1.nii',...
%         'MNIFolder', 'C:\Users\Josh\Dropbox\Globals\MNI',...
%         'ROIFolder', 'C:\Users\Josh\Dropbox\Globals\MNI\roi',...
%         'SegmentsFolder', 'C:\Users\Josh\Dropbox\Globals\MNI\segments',...
%         'SubjectFolderStr', 'DMC_003'),...
%     'Segmentation', struct(...
%         'BiasReg', 0.0001,...
%         'BiasFWHM', 60,...
%         'Cleanup', false,...
%         'MaskImage', {{''}},...
%         'NumGauss', [2 2 2 4],...
%         'OutputCorrected', true,...
%         'OutputCSF', [0 0 1],...
%         'OutputGM', [0 0 1],...
%         'OutputWM', [0 0 1],...
%         'RegType', 'mni',...
%         'SampleDistance', 3,...
%         'WarpReg', true,...
%         'WarpCutoff', 25),...
%     'Registration', struct(...
%         'CostFunction', 'nmi',...
%         'FWHMSmoothing', [7 7],...
%         'Interpolation', 1,...
%         'Masking', 0,...
%         'OutputPrefix', 'r',...
%         'Separation', [4 2],...
%         'Tolerances', [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001 0.001],...
%         'Wrapping', [0 0 0]),...
%     'Normalization', struct(...
%         'AmtRegularization', 1,...
%         'BoundingBox', [-78 -112 -50; 78 76 85],...
%         'DCTCutoff', 25,...
%         'Interpolation', 1,...
%         'Masking', false,...
%         'NormPrefix', 'w',...
%         'NumIterations', 16,...
%         'Preservation', 0,...
%         'RegPrefix', 'r',...
%         'Regularization', 'mni',...
%         'SourceSmoothing', 8,...
%         'TemplateImage', [],...
%         'TemplateSmoothing', 0,...
%         'TemplateWeightImage', {''},...
%         'VoxelSize', [2 2 2],...
%         'Wrapping', [0 0 0]),...
%     'Conditioning', struct(...
%         'BlurMasks', true,...
%         'CSFCutoff', 0.2,...
%         'DetrendOrder', 2,...
%         'FilterData', true,...
%         'FilterLength', 45,...
%         'GMCutoff', 0.1,...
%         'MeanCutoff', 0.2,...
%         'NumPCToRegress', NaN,...
%         'NumTRToRemove', 0,...
%         'Passband', [0.01 0.08],...
%         'PCAVarCutoff', 0.0001,...
%         'RegressCSF', false,...
%         'RegressGlobal', false,...
%         'SpatialBlurSigma', 2,...
%         'SpatialBlurSize', 3,...
%         'UsePCA', false,...
%         'UseZeroPhaseFilter', true,...
%         'WMCutoff', 0.15));
% 
% % Add in defaults that couldn't be filled in just before
% paramStruct.Normalization.TemplateImage = {[paramStruct.Initialization.MNIBrain ',1']};