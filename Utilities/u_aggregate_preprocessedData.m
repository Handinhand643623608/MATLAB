function u_aggregate_preprocessedData(fileStruct, paramStruct)


%% Initialize
subjects = paramStruct.general.subjects;
scans = paramStruct.general.scans;

%% Aggregate the EEG Data
% Initialize output structure for raw EEG data
if exist([fileStruct.paths.MAT_files '/EEG/EEG_data_raw.mat'], 'file')
    load EEG_data_raw;
else
    EEG_data = f_CA_initialize_datastruct('EEG', paramStruct);
end

% Aggregate new raw EEG files
for i = subjects
    for j = scans{i}
        filename = ['tempEEG_raw_' num2str(i) '_' num2str(j) '.mat'];
        if exist(filename, 'file')
            % Load the data to be aggregated
            temp = load(filename);

            % Transfer the EEG data
            EEG_data(i, j) = temp.EEG_data;

            % Garbage collect
            clear temp;
        end
    end
end

% Save the data & garbage collect
save([fileStruct.paths.MAT_files '/EEG/EEG_data_raw.mat'], 'EEG_data', '-v7.3')
clear EEG_data
delete([fileStruct.paths.MAT_files '/EEG/tempEEG_raw_*.mat'])        

% Initialize output structure for filtered, downsampled EEG data
if exist([fileStruct.paths.MAT_files '/EEG/EEG_data_filtered_downsampled.mat'], 'file')
    load EEG_data_filtered_downsampled;
else
    EEG_data = f_CA_initialize_datastruct('EEG', paramStruct);
end

% Aggregate new filtered, downsampled EEG files
for i = subjects
    for j = scans{i}
        filename = ['tempEEG_filtered_downsampled_' num2str(i) '_' num2str(j) '.mat'];
        if exist(filename, 'file')
            % Load the data to be aggregated
            temp = load(filename);

            % Transfer the EEG data
            EEG_data(i, j) = temp.EEG_data;

            % Garbage collect
            clear temp;
        end
    end
end

% Save the data & garbage collect
save([fileStruct.paths.MAT_files '/EEG/EEG_data_filtered_downsampled.mat'], 'EEG_data', '-v7.3')
clear EEG_data
delete([fileStruct.paths.MAT_files '/EEG/tempEEG_filtered_downsampled_*.mat'])

% Initialize output structure for filtered EEG data
if exist([fileStruct.paths.MAT_files '/EEG/EEG_data_filtered.mat'], 'file')
    load EEG_data_filtered;
else
    EEG_data = f_CA_initialize_datastruct('EEG', paramStruct);
end

% Aggregate new filetered EEG files
for i = subjects
    for j = scans{i}
        filename = ['tempEEG_filtered_' num2str(i) '_' num2str(j) '.mat'];
        if exist(filename, 'file')
            % Load the data to be aggregated
            temp = load(filename);

            % Transfer the EEG data
            EEG_data(i, j) = temp.EEG_data;

            % Garbage collect
            clear temp;
        end
    end
end

% Save the data & garbage collect
save([fileStruct.paths.MAT_files '/EEG/EEG_data_filtered.mat'], 'EEG_data', '-v7.3')
clear EEG_data
delete([fileStruct.paths.MAT_files '/EEG/tempEEG_filtered_*.mat'])

%% Aggregate the BOLD Data
% Initialize output structure for preprocessed BOLD data
for i = subjects
    %Initialize the output structure for preprocessed BOLD data
    BOLD_data = f_CA_initialize_datastruct('BOLD', paramStruct, i, scans{i});
    
    for j = scans{i}
        saveFlag = 0;
        filename = [fileStruct.paths.MAT_files '/BOLD/tempBOLD_preprocessed_' num2str(i) '_' num2str(j) '.mat'];
        if exist(filename, 'file')
            % Load the data to be aggregated
            temp = load(filename);

            % Transfer the BOLD data
            BOLD_data.BOLD(j) = temp.BOLD_data.BOLD(j);
            BOLD_data.masks = temp.BOLD_data.masks;
            BOLD_data.anatomical = temp.BOLD_data.anatomical;

            % Garbage collect
            clear temp
            saveFlag = 1;
        end
    end
    
    % Save the data & garbage collect
    if saveFlag
        save([fileStruct.paths.MAT_files '/BOLD/BOLD_data_subject_' num2str(i) '.mat'], 'BOLD_data', '-v7.3')
        delete([fileStruct.paths.MAT_files '/BOLD/tempBOLD_preprocessed_' num2str(i) '*.mat']);
    end
    clear BOLD_data 
    
end    
        