function [human_data num_volumes] = preprocess(this_functional_folder,this_anatomical_folder,this_IMG_folder,segments_folder,ROI_folder,MNI_brain,num_file_slices,TR,num_actual_slices,filter_length_seconds)
% PREPROCESS
%
% Pre-processes a single subject, single scan data file
%   Written by Garth Thompson
%       20130614:   Updated by Josh Grooms to remove EEG fields from data
%                   structure.
%       20130628:   Replaced "dataobject_dicom_import" with an optimized
%                   and less error-prone equivalent function.


    
% Initialize dataobject
humanData = dataStructInitialize(paramStruct.Initialize);
%     human_data = dataobject_initialize(this_functional_folder,this_anatomical_folder,this_IMG_folder,segments_folder,ROI_folder,MNI_brain,num_file_slices,TR);
    
% Create a mean functional dicom
humanData = dataStructMeanDicom(humanData);    
%     human_data = dataobject_mean_dicom_from_folder(human_data);
    
% Import the dicoms
humanData = dataStructImportDCM(humanData);
%     human_data = dataobject_dicom_import(human_data);

% Segment the anatomical image
humanData = dataStructSegment(humanData, paramStruct.Segmentation);
%     human_data = dataobject_segment(human_data);

% Motion and slice timing corrections in AFNI
dataStructAFNIPreprocess(humanData);
%   human_data = dataobject_AFNI_preprocess(human_data,num_actual_slices,'alt+z');
    
% Convert AFNI to SPM friendly output
humanData = dataStructConvertBRIK(dataStruct);
%     human_data = dataobject_BRIK_to_NIFTI(human_data);

% Register functional images to anatomical image
humanData = dataStructRegister(humanData, paramStruct.Registration);
%     human_data = dataobject_registration(human_data,1);
    
% Normalize to template brain
humanData = dataStructNormalize(humanData, paramStruct.Normalization);
%     human_data = dataobject_normalize_to_template(human_data,MNI_brain);

% Import data
humanData = dataStructImportIMG(humanData);
%     human_data = dataobject_IMG_import(human_data,'n');
%     num_volumes = size(human_data.data.bold{1},length(size(human_data.data.bold{1})));
    
% Do Waqas' old preprocessing on the time courses
humanData = dataStructConditionBOLD(humanData, paramStruct.Conditioning);
%     human_data = dataobject_BOLD_normalize_filter_detrend_regress(human_data, ...
%         0, ...          % Number of TRs to remove
%         2, ...          % Sigma for spatial gaussian blur
%         3, ...          % Size (voxels) of spatial gaussian blur
%         0.1, ...        % Cutoff for normalized (0 < GM < 1) gray matter mask
%         0.15, ...       % Cutoff for normalized white matter mask
%         0.2, ...        % Cutoff for normalized cerebrospinal fluid mask
%         0.2, ...        % Cutoff for normalized (0 < mn < 1) mean image
%         round(filter_length_seconds ./ TR), ...
%         0.01, ...       % Filter lower cutoff (highpass) Hz
%         0.08, ...       % Filter upper cutoff (lowpass) Hz
%         2, ...          % Order of de-trending function
%         0.0001, ...     % Variance cutoff for principal component analysis
%         NaN, ...        % Number of principal components to regress
%         true, ...       % Whether to regress cerebrospinal fluid signal or not
%         true, ...       % Whether to use the old method (non-PCA) or not
%         true ...        % Whether to blur the GM, WM and CSF masks or not
%         );
%     