function PrepNormalize(boldData)
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
allImages = cellfun(@(x) ([x ',1']), allImages, 'UniformOutput', false);
mniTemplate = {[params.MNIBrainTemplate ',1']};

% Initialize the SPM normalization batch processing
normBatch{1}.spm.spatial.normalise.estwrite = struct(...
    'eoptions', struct(...
        'regtype',          params.Regularization,...
        'smoref',           params.TemplateSmoothing,...
        'smosrc',           params.SourceSmoothing,...
        'template',         {mniTemplate},...
        'weight',           params.TemplateWeightImage),...
    'roptions', struct(...
        'bb',               params.BoundingBox,...
        'interp',           params.Interpolation,...
        'prefix',           params.NormPrefix,...
        'preserve',         params.Preservation,...
        'vox',              params.VoxelSize,...
        'wrap',             params.Wrapping),...
    'subj', struct(...
        'resample',         {allImages},...
        'source',           {[data.BiasCorrected ',1']},...
        'wtsrc',            ''));
    
% Initialize the SPM coregistration batch processing
regBatch{1}.spm.spatial.coreg.write = struct(...
    'ref',                  {mniTemplate},...
    'roptions', struct(...
        'interp',           params.Interpolation,...
        'mask',             params.Masking,...    
        'prefix',           params.RegPrefix,...
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