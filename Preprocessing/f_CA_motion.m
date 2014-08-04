function [BOLD_data fileStruct] = f_CA_motion(BOLD_data, fileStruct)

%% Initialize
% Initialize function-specific parameters
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;

% Load data stored elsewhere
load batch_realign;

%% Motion Correction
% Initialize important parameters
functional_filenames = f_CA_filenames(fileStruct.paths.corrected_functional{subject}{scan}, 'img');

% Append a '1' to the end of filenames for SPM session
for i = 1:length(functional_filenames)
    functional_filenames{i} = [functional_filenames{i} ',1'];
end

% Set SPM parameters
matlabbatch{1}.spm.spatial.realign.estwrite.data = {functional_filenames};

% Run SPM
spm_output = spm_jobman('run', matlabbatch);

% Delete uncorrected functional images
delete([fileStruct.paths.corrected_functional{subject}{scan} '/f*.img']);
delete([fileStruct.paths.corrected_functional{subject}{scan} '/f*.hdr']);


