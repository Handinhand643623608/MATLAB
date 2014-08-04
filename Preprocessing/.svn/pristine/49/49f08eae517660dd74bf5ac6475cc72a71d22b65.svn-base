function [BOLD_data fileStruct] = f_CA_segment_structural(BOLD_data, fileStruct)

% F_CA_SEGMENT_STRUCTURAL Segments structural images into white, gray, and CSF
%   masks, and corrects for coil bias. 
%
%   Unknown Author (from SPM)
%       Modified by Josh Grooms on 6/15/2012 to work with new data
%       structures & to work with new pre-made SPM batch files
% 
%% Initialize
% Load data stored elsewhere
load batch_segment;

% Assign variables
subject = BOLD_data.info.subject;
scans = BOLD_data.info.scans;
output_GM = matlabbatch{1}.spm.spatial.preproc.output.GM;
output_WM = matlabbatch{1}.spm.spatial.preproc.output.WM;
output_CSF = matlabbatch{1}.spm.spatial.preproc.output.CSF;

% Initialize loop-specific parameters
anatomical_input_file = f_CA_filenames(fileStruct.paths.anatomical{subject}, 'img');
anatomical_folder = fileStruct.paths.anatomical{subject};

% Set SPM input parameter
matlabbatch{1}.spm.spatial.preproc.opts.tpm = f_CA_filenames(fileStruct.paths.segments, 'nii');
matlabbatch{1}.spm.spatial.preproc.data = anatomical_input_file;

% Run the SPM batch
spm_output = spm_jobman('run',matlabbatch);    

% Save the output
num_outputs = sum([output_GM output_WM output_CSF]);
fileStruct.files.segments{subject} = cell(num_outputs,1);

% Maskes for segmentation of structural image.
for index = 1:num_outputs
    eval(['fileStruct.files.segments{subject}(index) = {spm_output{1}.c' num2str(index) '{1}};']);
end

% Coil bias corrected structural image
fileStruct.files.anatomical{subject} = spm_output{1}.biascorr{1};

% Garbage collect
delete([fileStruct.paths.anatomical{subject} '/s*.img']);
delete([fileStruct.paths.anatomical{subject} '/s*.hdr']);

% Save structures
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');
