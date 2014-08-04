function data_object = dataobject_initialize(functional_folder,anatomical_folder,IMG_folder,segments_folder,ROI_folder,MNI_brain,num_file_slices,TR,ephys_folder,ephys_rate)
% INITIALIZE_data_object
% Creates a data structure to store human fMRI data
%
% data_object =
% dataobject_initialize(
% functional_folder,    Folder containing functional DICOMs
% anatomical_folder,    Folder containing anatomical DICOM
% IMG_folder,           Folder to save IMG/NII format SPM output
% segments_folder,      Folder containing IMG/NII gray matter, white matter
%                       and csf probability maps
% ROI_folder,           Folder containing IMG/NII format regions of interest
% MNI_brain,            Location of template brain file in IMG/NII format
% num_file_slices,      The number of slices 
% TR,                   TR of BOLD imaging (1/sampling rate)
% ephys_folder,         EEG, LFP, etc. co-registered to BOLD (optional)
% ephys_rate,           Sampling rate for the previous
% )

% Handle missing arguments
if ~exist('num_file_slices','var')
    num_file_slices = 1;
end

% Fix missing / at end of directory names
if ~(strcmp(functional_folder(end),'/') || strcmp(functional_folder(end),'/'))
    functional_folder = [functional_folder '/'];
end
if ~(strcmp(anatomical_folder(end),'/') || strcmp(anatomical_folder(end),'/'))
    anatomical_folder = [anatomical_folder '/'];
end
if exist('ROI_folder','var')
    if ~isempty(ROI_folder)
        if ~(strcmp(ROI_folder(end),'/') || strcmp(ROI_folder(end),'/'))
            ROI_folder = [ROI_folder '/'];
        end
    end
end
if ~(strcmp(IMG_folder(end),'/') || strcmp(IMG_folder(end),'/'))
    IMG_folder = [IMG_folder '/'];
end
if ~(strcmp(segments_folder(end),'/') || strcmp(segments_folder(end),'/'))
    segments_folder = [segments_folder '/'];
end

% Create the IMG folder if it doesn't exist
if ~exist(IMG_folder,'dir')
    mkdir(IMG_folder);
end

data_object = [];

% Load initial data into data structure
data_object.files.functional_folder = functional_folder;
data_object.files.anatomical_folder = anatomical_folder;
data_object.files.MNI_brain = MNI_brain;
data_object.files.IMG_folder = IMG_folder;
data_object.files.ROI_folder = ROI_folder;
data_object.files.num_file_slices = num_file_slices;
data_object.parameters.bold_tr(1) = TR;
data_object.files.segments_folder = segments_folder;

% Ephys only if input
if exist('ephys_folder','var')
    data_object.files.ephys_folder = ephys_folder;
end
if exist('ephys_rate','var')
    data_object.parameters.ephys_sampling_rate(1) = ephys_rate;
end