function data_object = dataobject_BRIK_to_NIFTI(data_object)
% DATAOBJECT_BRIK_TO_NIFTI
% Converts AFNI .BRIK and .head output to a format that SPM can read.
%

% Extract folder names
functional_folder = data_object.files.functional_folder;
img_folder = data_object.files.IMG_folder;

% Get filename of BRIK files that have been time and motion corrected
tshift_reg_dir = dir([functional_folder '*_tshift_reg*.BRIK']);
if length(tshift_reg_dir) > 1
    error(['Too many time shifted, motion corrected BRIK files in folder ' functional_folder]);
end
tshift_reg_file = tshift_reg_dir(1).name;
% Get the dset name used by AFNI
[not_used dset not_used] = segment_filename(tshift_reg_file);

% aname to use in AFNI
aname = 'tshift_reg';
mean_aname = 'mean_template';

% Save current directory
old_dir = pwd;
try
    % Change to functional directory
    cd(functional_folder);
    % Run AFNI script
    system(['3dAFNItoANALYZE -orient rpi ' aname ' ' dset]);
    % Move files to IMG folder
    movefile([functional_folder aname '_*.img'],img_folder);
    movefile([functional_folder aname '_*.hdr'],img_folder);
catch my_error
    % Change back the directory even if an error occurred
    cd(old_dir);
    throw(my_error);
end
% Also do mean image
try
    % Change to mean file folder
    cd([functional_folder 'mean/']);
    % Get mean filename
    mean_dir = dir([functional_folder 'mean/*.BRIK']);
    [not_used mean_dset not_used] = segment_filename(mean_dir(1).name);
    % Run AFNI script
    system(['3dAFNItoANALYZE -orient rpi ' mean_aname ' ' mean_dset]);
    % Get the new filename
    mean_new_dir = dir([functional_folder 'mean/' mean_aname '*.img']);
    % OVERWRITE OLD MEAN WITH NEW
    data_object.files.img.mean = [functional_folder 'mean/' mean_new_dir(1).name];
catch my_error
    cd(old_dir);
    disp(['Mean image not found or improper. Error message was ''' my_error.message '''']);
end
% Return to correct directory
cd(old_dir);

% Save functional searchstring for SPM to use
data_object.files.img.corrected_functional_searchstring = [img_folder aname '_*.img'];
