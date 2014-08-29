function PrepDCMToIMG(boldData)
%PREPDCMTOIMG - Converts DICOM image files into NIFTI format for SPM to use.
%   This function uses SPM's batch processing system to convert a series of DICOM image files into the NIFTI file
%   format, which is what SPM works with pretty much exclusively. Both anatomical and functional DICOM images are
%   converted by default.
%
%   SYNTAX:
%   PrepDCMToIMG(boldData)
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A single BOLD data object undergoing preprocessing.

%% CHANGELOG
%   Written by Josh Grooms on 20140721



%% Initialize
% Get folder references from the data object
anatomicalFolder = boldData.Preprocessing.Folders.Anatomical;
functionalFolder = boldData.Preprocessing.Folders.Functional;
imgFolder = boldData.Preprocessing.Folders.IMG.Root;

% Identify DICOM files
anatomicalFiles = get(fileData(anatomicalFolder, 'ext', '.dcm'), 'Path');
functionalFiles = get(fileData(functionalFolder, 'ext', '.dcm'), 'Path');



%% Convert DICOM Files
% Convert anatomical DICOM files to NIFTI format
matlabbatch{1}.spm.util.dicom = struct(...
    'convopts', struct(...
        'format', 'img',...
        'icedims', 0),...
    'data', {anatomicalFiles},...
    'outdir', {{imgFolder}},...
    'root', 'flat');

% Convert functional DICOM files to NIFTI format
matlabbatch{2}.spm.util.dicom = struct(...
    'convopts', struct(...
        'format', 'img',...
        'icedims', 0),...
    'data', {functionalFiles},...
    'outdir', {{imgFolder}},...
    'root', 'flat');

spmOutput = spm_jobman('run', matlabbatch);



%% Store File References in the Data Object
boldData.Preprocessing.Files.DCM.Anatomical = anatomicalFiles;
boldData.Preprocessing.Files.DCM.Functional = functionalFiles;
boldData.Preprocessing.Files.IMG.Anatomical = spmOutput{1}.files;
boldData.Preprocessing.Files.IMG.Functional = spmOutput{2}.files;