function [BOLD_data fileStruct] = f_CA_slicetime(BOLD_data, fileStruct, paramStruct)

%% Initialize
% Load data stored elsewhere
load batch_slicetime
    
% Initialize function-specific parameters
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;
TR = paramStruct.initialize.BOLD.TR;

%% Slice Timing Correction
% Initialize loop-dependent parameters
num_file_slices = 1;
mean_dcm = [fileStruct.paths.raw_functional{subject}{scan} '/mean/mean.dcm'];
mean_img = f_CA_filenames(fileStruct.paths.mean{subject}{scan}, 'img');
    fileStruct.files.mean{subject}{scan} = mean_img{1};    
functional_filenames = f_CA_filenames(fileStruct.paths.corrected_functional{subject}{scan}, 'rf', 'img');

% Determine the total number of slices to be in one file
info = dicominfo(mean_dcm);
nslices = num_file_slices * ((double(info.Width) * double(info.Height)) / prod(double(info.AcquisitionMatrix(info.AcquisitionMatrix ~= 0))));

% Append a '1' to the end of the functional file names for SPM
for j = 1:length(functional_filenames)
    functional_filenames{j} = [functional_filenames{j} ',1'];
end

% Set SPM parameters
matlabbatch{1}.spm.temporal.st.scans = {functional_filenames};
matlabbatch{1}.spm.temporal.st.nslices = nslices;
matlabbatch{1}.spm.temporal.st.ta = (TR - (TR/nslices));
matlabbatch{1}.spm.temporal.st.so = [(nslices:-2:1) ((nslices - 1):-2:1)];

% Run SPM
spm_output = spm_jobman('run', matlabbatch);

% Delete uncorrected functional images (IMG files starting with 'f')
delete([fileStruct.paths.corrected_functional{subject}{scan} '/r*.img']);
delete([fileStruct.paths.corrected_functional{subject}{scan} '/r*.hdr']);

% Save structures
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');
