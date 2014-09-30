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
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.


%% Initialize
% Get the scan-specific data from the data object
data = boldData.Preprocessing.ScanData;

% Initialize SPM batch processing
spm_jobman('initcfg');



%% Convert DICOM Files

% Convert anatomical DICOM files to NIFTI format
matlabbatch{1}.spm.util.dicom = struct(...
    'convopts', struct(...
        'format', 'img',...
        'icedims', 0),...
    'data', {data.RawAnatomicalFiles},...
    'outdir', {{data.IMGFolder}},...
    'root', 'flat');

% Convert functional DICOM files to NIFTI format
matlabbatch{2}.spm.util.dicom = struct(...
    'convopts', struct(...
        'format', 'img',...
        'icedims', 0),...
    'data', {data.RawFunctionalFiles},...
    'outdir', {{data.IMGFolder}},...
    'root', 'flat');

% Run SPM's batch conversion process
spmOutput = spm_jobman('run', matlabbatch);



%% Store File References in the Data Object
boldData.Preprocessing.WorkingData = struct(...
    'Anatomical', {spmOutput{1}.files},...
    'Functional', {spmOutput{2}.files});

% 
% boldData.Preprocessing.Files.DCM.Anatomical = anatomicalFiles;
% boldData.Preprocessing.Files.DCM.Functional = functionalFiles;
% boldData.Preprocessing.Files.IMG.Anatomical = spmOutput{1}.files;
% boldData.Preprocessing.Files.IMG.Functional = spmOutput{2}.files;