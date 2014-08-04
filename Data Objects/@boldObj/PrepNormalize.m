function PrepNormalize(boldData, varargin)
%PREPNORMALIZE
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
%   'AmtRegularization':
%
%   'BoundingBox':
%   
%   'DCTCutoff':
%   
%   'Interpolation':
%
%   'Masking':
%
%   'NormPrefix':
%
%   'NumIterations':
%
%   'Preservation':
%
%   'RegPrefix':
%   
%   'Regularization':
%
%   'SourceSmoothing':
%   
%   'TemplateImage':
%   
%   'TemplateSmoothing':
%
%   'TemplateWeightImage':
%
%   'VoxelSize':
%
%   'Wrapping':



%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20140721:   Changed the way IMG files were being identified here and in other related SPM preprocessing
%                   functions. File references are now passed along from stage to stage in the pipeline, eliminating the
%                   need for searching through directories. Removed the separate template image parameter from this
%                   preprocessing stage, since the MNI brain was the only one ever used and there's an existing
%                   reference to it elsewhere.



%% TODOS
% Immediate Todos
% - Complete documentation for this method.



%% Initialize
% Initialize defaults & settings
if nargin == 1
    assignInputs(boldData.Preprocessing.Parameters.Normalization, 'varsOnly');
elseif isstruct(varargin{1})
    assignInputs(varargin{1}, 'varsOnly')
else
    inSruct = struct(...
        'AmtRegularization', 1,...
        'BoundingBox', [-78 -112 -50; 78 76 85],...
        'DCTCutoff', 25,...
        'Interpolation', 1,...
        'Masking', false,...
        'NormPrefix', 'w',...
        'NumIterations', 16,...
        'Preservation', 0,...
        'RegPrefix', 'r',...
        'Regularization', 'mni',...
        'SourceSmoothing', 8,...
        'TemplateImage', {{[boldData.Preprocessing.Files.MNIBrain ',1']}},...
        'TemplateSmoothing', 0,...
        'TemplateWeightImage', {''},...
        'VoxelSize', [2 2 2],...
        'Wrapping', [0 0 0]);
    assignInputs(inStruct, varargin)
end    
    
% Pull information from the data structure
biasCorIMG = {[boldData.Preprocessing.Files.IMG.BiasCorrected ',1']};
functionalIMG = boldData.Preprocessing.Files.IMG.Functional;
meanIMG = {boldData.Preprocessing.Files.IMG.Mean};
mniTemplate = {[boldData.Preprocessing.Files.MNIBrain ',1']};
segmentIMG = boldData.Preprocessing.Files.IMG.Segments;

% Compile a list of images for SPM
segmentIMG = cellfun(@(x) [x, '1'], segmentIMG, 'UniformOutput', false);
resampleImages = cat(1, biasCorIMG, meanIMG, segmentIMG, functionalIMG);

% Initialize the SPM normalization batch processing
normBatch{1}.spm.spatial.normalise.estwrite = struct(...
    'eoptions', struct(...
        'regtype', Regularization,...
        'smoref', TemplateSmoothing,...
        'smosrc', SourceSmoothing,...
        'template', {mniTemplate},...
        'weight', TemplateWeightImage),...
    'roptions', struct(...
        'bb', BoundingBox,...
        'interp', Interpolation,...
        'prefix', NormPrefix,...
        'preserve', Preservation,...
        'vox', VoxelSize,...
        'wrap', Wrapping),...
    'subj', struct(...
        'resample', {resampleImages},...
        'source', {biasCorIMG},...
        'wtsrc', ''));
    
% Initialize the SPM coregistration batch processing
regBatch{1}.spm.spatial.coreg.write = struct(...
    'ref', {mniTemplate},...
    'roptions', struct(...
        'interp', Interpolation,...
        'mask', Masking,...    
        'prefix', RegPrefix,...
        'wrap', Wrapping),...
    'source', []);



%% Run SPM Normalization
% Normalize to the template image
normOutput = spm_jobman('run', normBatch);
regBatch{1}.spm.spatial.coreg.write.source = normOutput{1}.files;
regOutput = spm_jobman('run', regBatch);
regOutput{1}.rfiles = regexprep(regOutput{1}.rfiles, ',1', '');



%% Store Information in Data Structure
boldData.Preprocessing.Files.IMG.BiasCorrected = regOutput{1}.rfiles{1};
boldData.Preprocessing.Files.IMG.Mean = regOutput{1}.rfiles{2};
boldData.Preprocessing.Files.IMG.Segments = regOutput{1}.rfiles(3:5);
boldData.Preprocessing.Files.IMG.Functional = regOutput{1}.rfiles(6:end);