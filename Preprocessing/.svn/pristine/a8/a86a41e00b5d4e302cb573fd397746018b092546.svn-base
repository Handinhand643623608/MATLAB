function [BOLD_data fileStruct] = f_CA_normalize(BOLD_data, fileStruct)

%% Initalize
% Initialize script-specific parameters
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;
segment_filenames = fileStruct.files.segments{subject};
anatomical_filename = [fileStruct.files.anatomical{subject} ',1'];
MNI_template = fileStruct.files.MNI;

% Append a '1' to the end of the segment file names    
for i = 1:length(segment_filenames)
    segment_filenames{i} = [segment_filenames{i} ',1'];
end

%% Normalize BOLD Data to MNI Brain

% Initialize loop-specific parameters
load batch_normalize
functional_filenames = f_CA_filenames(fileStruct.paths.corrected_functional{subject}{scan}, 'rarf', 'img');
reg_mean_img = [fileStruct.files.mean{subject}{scan} ',1'];

% Append a '1' to the end of all functional file names for SPM
for i = 1:length(functional_filenames)
    functional_filenames{i} = [functional_filenames{i} ',1'];
end

% Compile the inputs for the 'resample' field for SPM
resample_input = cat(1, ...
    {anatomical_filename},...
    {reg_mean_img},...
    segment_filenames,...
    functional_filenames);

% Set SPM batch parameters
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {anatomical_filename};
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.wtsrc = '';
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = resample_input;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = {MNI_template};

% Run the SPM batch (normalize to anatomical first)
spm_output = spm_jobman('run', matlabbatch);

% Delete uncorrected functional IMG files
delete([fileStruct.paths.corrected_functional{subject}{scan} '/r*.img']);
delete([fileStruct.paths.corrected_functional{subject}{scan} '/r*.hdr']);
delete([fileStruct.paths.mean{subject}{scan} '/r*.img']);
delete([fileStruct.paths.mean{subject}{scan} '/r*.hdr']);

% Set new SPM batch parameters using normalized files from first batch
load batch_normalize_reslice
matlabbatch{1}.spm.spatial.coreg.write.ref = {MNI_template};
matlabbatch{1}.spm.spatial.coreg.write.source = spm_output{1}.files;

% Run the SPM job (normalize to template image now)
spm_output = spm_jobman('run', matlabbatch);

% Save the output mean file names in the file structure
fileStruct.files.mean{subject}{scan} = spm_output{1}.rfiles{2}(1:(end-2));

% Delete uncorrected functional IMG files
delete([fileStruct.paths.corrected_functional{subject}{scan} '/w*.img']);
delete([fileStruct.paths.corrected_functional{subject}{scan} '/w*.hdr']);
delete([fileStruct.paths.anatomical{subject} '/w*.img']);
delete([fileStruct.paths.anatomical{subject} '/w*.hdr']);
delete([fileStruct.paths.mean{subject}{scan} '/w*.img']);
delete([fileStruct.paths.mean{subject}{scan} '/w*.hdr']);

% Save the output anatomical file names in the file structure
fileStruct.files.anatomical{subject} = spm_output{1}.rfiles{1}(1:(end - 2));

% Store the segments
temp_segments = spm_output{1}.rfiles(3:(length(segment_filenames)+2));
for i = 1:length(segment_filenames)
    fileStruct.files.segments{subject}(i) = {temp_segments{i}(1:(end - 2))};
end

% Save structures
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');