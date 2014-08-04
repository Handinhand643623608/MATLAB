function [BOLD_data paramStruct] = f_CA_import_IMG(BOLD_data, fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;
segment_filenames = fileStruct.files.segments{subject}; 
anatomical_filename = fileStruct.files.anatomical{subject};

% Load the anatomical data first
anatomical_data = load_nii(anatomical_filename);
    anatomical_data = anatomical_data.img;

% Store the anatomical data
BOLD_data.anatomical = double(anatomical_data);
    
%% Import the IMG Files
% Initialize loop-specific parameters
mean_filename = fileStruct.files.mean{subject}{scan};
functional_filenames = f_CA_filenames(fileStruct.paths.corrected_functional{subject}{scan}, 'rwrarf', 'img');

% Load the IMG data in MATLAB
mean_data = load_nii(mean_filename);
    mean_data = mean_data.img;
functional_data = zeros(size(mean_data, 1), size(mean_data, 2), size(mean_data, 3), length(functional_filenames));
for i = 1:length(functional_filenames)
    current_img = load_nii(functional_filenames{i});
        current_img = current_img.img;
    functional_data(:, :, :, i) = current_img;
end

% Store the IMG data in the output structure
BOLD_data.BOLD(scan).mean = double(mean_data);
BOLD_data.BOLD(scan).functional = double(functional_data);   

% Load the mask data
ROI_data = zeros(size(mean_data, 1), size(mean_data, 2), size(mean_data, 3), length(segment_filenames));
for i = 1:length(segment_filenames)
    current_img = load_nii(segment_filenames{i});
        current_img = current_img.img;
    ROI_data(:, :, :, i) = current_img;
end

% Separate the ROIs
CSF_data = ROI_data(:, :, :, 1);
GM_data = ROI_data(:, :, :, 2);
WM_data = ROI_data(:, :, :, 3);

% Store masks in the output structure
BOLD_data.masks.GM = double(GM_data);
BOLD_data.masks.WM = double(WM_data);
BOLD_data.masks.CSF = double(CSF_data);

% Store information needed later in analysis
BOLD_data.info.num_timepoints = size(functional_data, 4);
paramStruct.preprocess.EEG.num_timepoints = size(functional_data, 4);

% Save structures & data
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');
save([fileStruct.paths.main '/tempParamStruct.mat'], 'paramStruct');
save([fileStruct.paths.main '/tempBOLDdata_sub' num2str(subject) '.mat'], 'BOLD_data', '-v7.3');
