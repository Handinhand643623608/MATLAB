function f_CA_preprocess

%% Initialize
if ~exist('masterStructs.mat', 'file')
    CA_masterStructs
    load masterStructs_incomplete.mat
else
    load masterStructs.mat
end

[fileStruct paramStruct] = f_CA_initialize(fileStruct, paramStruct);

% Control whether to append data or create a new set using all subjects/scans
if paramStruct.general.append
    subjects = paramStruct.general.appendSubjects;
else
    subjects = paramStruct.general.subjects;
end

%% Preprocess BOLD & EEG Data
for i = [7]
    for j = paramStruct.general.scans{i}

        % Initialize the BOLD data structure
        BOLD_data = f_CA_initialize_datastruct('BOLD', paramStruct, i, j);
        % Create a mean functional DICOM
        [BOLD_data fileStruct] = f_CA_mean_dicom(BOLD_data, fileStruct);
        % Convert DICOMs to IMG & import
        [BOLD_data fileStruct] = f_CA_import_dicoms(BOLD_data, fileStruct);
        % Correct MRI scans for subject motion
        [BOLD_data fileStruct] = f_CA_motion(BOLD_data, fileStruct);
        % Correct MRI scans for slice timing
        [BOLD_data fileStruct] = f_CA_slicetime(BOLD_data, fileStruct, paramStruct);
        % Segment the anatomical images
        if isempty(fileStruct.files.anatomical{i})
            [BOLD_data fileStruct] = f_CA_segment_structural(BOLD_data, fileStruct);
        end
        % Coregister functional to anatomical images
        [BOLD_data fileStruct] = f_CA_coregister(BOLD_data, fileStruct);
        % Normalize MRI scans to an MNI template
        [BOLD_data fileStruct] = f_CA_normalize(BOLD_data, fileStruct);
        % Import IMG data to MATLAB
        [BOLD_data paramStruct] = f_CA_import_IMG(BOLD_data, fileStruct, paramStruct);
        % Perform temporal preprocessing on BOLD data
        [BOLD_data fileStruct paramStruct] = f_CA_preprocess_BOLD_timecourses(BOLD_data, fileStruct, paramStruct);
        % Garbage collect
        clear BOLD_data
        close all
        clc

        for i = 8
            for j = paramStruct.general.scans{i}
        % Initialize the EEG data structure
        EEG_data = f_CA_initialize_datastruct('EEG', paramStruct, i, j);
        % Import the EEG data
        EEG_data = f_CA_import_cnt(EEG_data, fileStruct, paramStruct);
        % Filter the EEG data
        EEG_data = f_CA_preprocess_EEG_timecourses(EEG_data, fileStruct, paramStruct);
        % Garbage collect
        clear EEG_data
        close all
        clc
        
        % Save the Structure Data
        save(fileStruct.files.masterStructs, 'fileStruct', 'paramStruct')
            end
        end
        
        
    end
    
    % Aggregate all separate data sets
    f_CA_aggregateData(fileStruct, paramStruct);
    paramStruct.general.append = 1;
    
    % Save the structure data
    save(fileStruct.files.masterStructs, 'fileStruct', 'paramStruct')
    
end
