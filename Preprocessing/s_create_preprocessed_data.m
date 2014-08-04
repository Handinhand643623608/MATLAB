% Creates preprocessed data from DICOM image files and from EEG data
% Modified by Josh Grooms on January 13, 2012 for the Keilholz Lab
%       Further modified on 2/7/2012 to correct EEG labeling

% One file per set of slices
num_file_slices = 1;
% 33 slices
num_actual_slices = 33;
% Resampled ephys rate
new_ephys_rate = 300;
% Number of subjects
subjects_to_run = [2 3 4 5 6 7 8];
% Each row is a subject, 1 if they have a usuable scan, 0 if they don't
scans_per_subject = [...
    1 1 1 1 0 0
    1 1 0 0 0 0
    1 1 1 0 0 0
    1 1 1 1 0 0
    1 1 1 1 0 0
    1 1 1 1 1 0
    1 1 1 1 0 0
    1 1 1 1 0 0];     
    
scans_vector = 1:6;
% Filter length, in seconds
filter_length_seconds = 45;

% Folder names
main_folder = '/shella-lab/Josh/Raw_Data/';
functional_subfolder_signifier = '/ep2d*';
anatomical_folder_signifier = '/t1*';
IMG_folder_signifier = '/IMG';
EEG_folder_signifier = '/EEG*';
segments_folder = '/shella-lab/Josh/Globals/MNI/segments';
ROI_folder = '/shella-lab/Josh/Globals/MNI/roi';
MNI_brain = '/shella-lab/Josh/Globals/MNI/template/T1.nii';
TR = 2.000; % Seconds

% Create list of subjects
subject_list = dir(main_folder);
subject_list = remove_dots_from_dirs(subject_list);

%  Which subjects have BCG
has_bcg = [0 0 0 0 0 0 0 0];
% Best channel to correct MR artifacts
best_channel = 63;

for subject_index = subjects_to_run
    subject_subfolder = subject_list(subject_index).name;
    % Get list of functional scans
    functional_scan_list = dir([main_folder subject_subfolder functional_subfolder_signifier]);
    functional_scan_list = remove_dots_from_dirs(functional_scan_list);
    num_scans = length(functional_scan_list);
    % Get anatomical scan
    this_anatomical_folder = dir([main_folder subject_subfolder anatomical_folder_signifier]);
    this_anatomical_folder = remove_dots_from_dirs(this_anatomical_folder);
    this_anatomical_folder = [main_folder subject_subfolder '/' this_anatomical_folder(1).name];
    % Get EEG files
    this_ephys_folder = dir([main_folder subject_subfolder EEG_folder_signifier]);
    this_ephys_folder = remove_dots_from_dirs(this_ephys_folder);
    this_ephys_folder = this_ephys_folder(1).name;
    this_ephys_folder = [main_folder subject_subfolder '/' this_ephys_folder]; %#ok<AGROW>
    for scan_index = scans_vector(boolean(scans_per_subject(subject_index,:)))
        this_functional_folder = [main_folder subject_subfolder '/' functional_scan_list(scan_index).name];
        this_IMG_folder = [this_functional_folder IMG_folder_signifier];
        
        % Indicate where the script currently is while running
        progress = sprintf('Begin preprocessing subject %d scan %d', subject_index, scan_index);
        disp(progress)
        
        [current_human_data num_volumes] = preprocess(this_functional_folder,this_anatomical_folder,this_IMG_folder,segments_folder,ROI_folder,MNI_brain,num_file_slices,TR,this_ephys_folder,new_ephys_rate,num_actual_slices,filter_length_seconds);
        % return;
        % Create new or append
        if scan_index == 1
            human_data = current_human_data;
        else
            human_data = dataobject_append_all(human_data,current_human_data);
        end
    end
    
    % Force relabeling of subjects 1-5 because the wrong setup file was used when gathering data
    if subject_index < 7
        force_relabel = 1;
    else
        force_relabel = 0;
    end
    
    % Add EEG
    progress = sprintf('Begin importing subject %d scan %d EEG data', subject_index, scan_index);
    disp(progress)
    
    human_data = f_dataobject_neuroscan_import(human_data,this_ephys_folder,new_ephys_rate,TR,num_volumes,num_actual_slices,[],'name',best_channel,has_bcg(subject_index),scans_vector(boolean(scans_per_subject(subject_index,:))), force_relabel);
    
    disp('Finished')

    % Save the data
    save(['/shella-lab/Josh/Raw_Data/human_data_' subject_subfolder '_withPVT.mat'],'human_data','-v7.3')
end
