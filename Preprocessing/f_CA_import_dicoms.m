function [BOLD_data fileStruct] = f_CA_import_dicoms(BOLD_data, fileStruct)
% F_CA_DICOM_IMPORT Imports the DICOM file names from the data folder
%  
%   Unknown Author (from SPM)
%       Modified by Josh Grooms on 6/14/2012 to work with new data
%       stuctures
%       Modified on 6/15/2012 to include new, pre-made SPM batch files
%       Modified heavily on 6/19/2012 to take advantage of multiple SPM
%       batches and to improve output file structure

%% Initialize
% Load data stored elsewhere
load batch_import_DICOMs;
    matlabbatch{2} = matlabbatch{1};

% Initialize function-specific variables
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;
anatomical_input_folder = fileStruct.paths.anatomical{subject};
if iscell(anatomical_input_folder)
    anatomical_input_folder = anatomical_input_folder{1};
end

%% Import the Anatomical & Mean DICOMs

% Input & output data paths
output_folder = [fileStruct.paths.preprocessed '/Subject ' num2str(subject) '/Scan ' num2str(scan)];
mean_input_file = {fileStruct.files.mean{subject}{scan}};
mean_output_folder = [output_folder '/Mean'];
    mkdir(mean_output_folder)
    fileStruct.paths.mean{subject}{scan} = mean_output_folder;
anatomical_output_folder = [fileStruct.paths.preprocessed '/Subject ' num2str(subject) '/Anatomical'];
    if exist(anatomical_output_folder, 'dir') ~= 7
        mkdir(anatomical_output_folder)
        fileStruct.paths.anatomical{subject} = anatomical_output_folder;
    end
functional_input_folder = fileStruct.paths.raw_functional{subject}{scan};
functional_output_folder = [output_folder '/Functional'];
    mkdir(functional_output_folder)
    fileStruct.paths.corrected_functional{subject}{scan} = functional_output_folder;

% Get a list of the anatomical files
anatomical_filenames = f_CA_filenames(anatomical_input_folder, 'dcm');

% Get a list of the functional files
functional_filenames = f_CA_filenames(functional_input_folder, 'dcm');

% Set SPM batch command for input files
matlabbatch{1}.spm.util.dicom.data = mean_input_file;
matlabbatch{2}.spm.util.dicom.data = functional_filenames;
if isempty(fileStruct.files.anatomical{subject})
    matlabbatch{3} = matlabbatch{1};
    matlabbatch{3}.spm.util.dicom.data = anatomical_filenames;
end

% Set SPM output directory
matlabbatch{1}.spm.util.dicom.outdir = {mean_output_folder};
matlabbatch{2}.spm.util.dicom.outdir = {functional_output_folder};
if isempty(fileStruct.files.anatomical{subject})
    matlabbatch{3}.spm.util.dicom.outdir = {anatomical_output_folder};
end

% Run the SPM batch
spm_output = spm_jobman('run', matlabbatch);

% Save structures
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');
