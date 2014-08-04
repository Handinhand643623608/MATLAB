function [BOLD_data fileStruct] = f_CA_coregister(BOLD_data, fileStruct)

%% Initialize
% Initialize script-specific variables
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;

% Load data stored elsewhere
load batch_coregister

%% Coregister Functional to Anatomical Images
% Initialize loop-specific parameters
anatomical_input = [fileStruct.files.anatomical{subject}, ',1'];
functional_input = f_CA_filenames(fileStruct.paths.corrected_functional{subject}{scan}, 'arf', 'img');
mean_img = [fileStruct.files.mean{subject}{scan} ',1'];

% Append a '1' to the end of each functional file name for SPM
for j = 1:length(functional_input)
    functional_input{j} = [functional_input{j} ',1'];
end

% Set SPM batch parameters
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {anatomical_input};      % <--- Anatomical image is the reference image
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {mean_img};           % <--- Mean image is to be resliced
matlabbatch{1}.spm.spatial.coreg.estwrite.other = functional_input;      % <--- Other images are functional images

% Run the SPM batch
spm_output = spm_jobman('run', matlabbatch);

% Delete uncorrected functional images
delete([fileStruct.paths.corrected_functional{subject}{scan} '/a*.img']);
delete([fileStruct.paths.corrected_functional{subject}{scan} '/a*.hdr']);

% Save the file name outputs (& trim the '1' off of it)
mean_filename = spm_output{1}.rfiles{1};
mean_filename((end - 1):end) = [];
fileStruct.files.mean{subject}{scan} = mean_filename;  

% Save structures
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');

