function EEG_data = f_CA_preprocess_EEG_timecourses(EEG_data, fileStruct, paramStruct);

%% Initialize
% Initialize function-specific variables
subject = EEG_data.info.subject;
scan = EEG_data.info.scan;

% Get the current data to be preprocessed
current_EEG = EEG_data.data.EEG';
if ~isempty(EEG_data.data.BCG);
    current_BCG = EEG_data.data.BCG';
end

% Get rid of NaNs in data
current_EEG(isnan(current_EEG)) = 0;
if ~isempty(EEG_data.data.BCG);
    current_BCG(isnan(current_BCG)) = 0;
end

% Filter the data
switch paramStruct.preprocess.EEG.filter_type;
    case 'bfilt'
        current_EEG = bfilt(...
            current_EEG,...
            paramStruct.preprocess.EEG.bandpass(1),...
            paramStruct.preprocess.EEG.bandpass(2),...
            EEG_data.info.Fs, 0);
        if ~isempty(EEG_data.data.BCG)
            current_BCG = bfilt(...
                current_BCG,...
                paramStruct.preprocess.EEG.bandpass(1),...
                paramStruct.preprocess.EEG.bandpass(2),...
                EEG_data.info.Fs, 0);
            sample_shift = 0;
        end
    case 'fir1'
        [current_EEG sample_shift] = firfilt(...
            current_EEG,...
            paramStruct.preprocess.EEG.bandpass(1),...
            paramStruct.preprocess.EEG.bandpass(2),...
            EEG_data.info.Fs,...
            paramStruct.preprocess.EEG.filt_params);
        if ~isempty(EEG_data.data.BCG)
            [current_BCG ~] = firfilt(...
                current_BCG,...
                paramStruct.preprocess.EEG.bandpass(1),...
                paramStruct.preprocess.EEG.bandpass(2),...
                EEG_data.info.Fs,...
                paramStruct.preprocess.EEG.filt_params);
        end
    case 'user'
        current_EEG = apply_fft_filter(...
            current_EEG,...
            EEG_data.info.Fs,...
            paramStruct.preprocess.EEG.filt_params(1),...
            paramStruct.preprocess.EEG.filt_params(2));
        if ~isempty(EEG_data.data.BCG)
            current_BCG = apply_fft_filter(...
                current_BCG,...
                EEG_data.info.Fs,...
                paramStruct.preprocess.EEG.filt_params(1),...
                paramStruct.preprocess.EEG.filt_params(2));
        end
    otherwise
        error('Unknown filter type input. EEG data cannot be filtered')
end

% Detrend the data
current_EEG = detrend_wm(current_EEG', paramStruct.preprocess.EEG.detrend_order);
if ~isempty(EEG_data.data.BCG)
    current_BCG = detrend_wm(current_BCG', paramStruct.preprocess.EEG.detrend_order);
end

% Z-score the EEG data for consistency with BOLD data
current_EEG = zscore(current_EEG, 0, 2);
if ~isempty(EEG_data.data.BCG)
    current_BCG = zscore(current_BCG, 0, 2);
end

% Store the data in the output structure
EEG_data.data.EEG = current_EEG;
if ~isempty(EEG_data.data.BCG)
    EEG_data.data.BCG = current_BCG;
end
EEG_data.info.num_timepoints = size(current_EEG, 2);
if exist('sample_shift', 'var')
    EEG_data.info.filter_shift = sample_shift;
end

% Save the preprocessed EEG data
save([fileStruct.paths.MAT_files '/EEG/tempEEG_filtered_' num2str(subject) '_' num2str(scan) '.mat'], 'EEG_data', '-v7.3')

%% Downsample the EEG Time Course to Match BOLD
% Collect data to be processed
current_EEG = EEG_data.data.EEG;
if ~isempty(EEG_data.data.BCG)
    current_BCG = EEG_data.data.BCG;
end

% Downsample the EEG data to the same number of time points as BOLD
current_EEG = resample(current_EEG', paramStruct.preprocess.EEG.target_timepoints, size(current_EEG, 2));
if ~isempty(EEG_data.data.BCG)
    current_BCG = resample(current_BCG', paramStruct.preprocess.EEG.target_timepoints, length(current_BCG));
end

% Store the data in the output structure
EEG_data.data.EEG = current_EEG';
if ~isempty(EEG_data.data.BCG)
    EEG_data.data.BCG = current_BCG';
end
EEG_data.info.Fs = 1/(paramStruct.initialize.BOLD.TR);
EEG_data.info.filter_shift = (EEG_data.info.filter_shift)*(1/paramStruct.preprocess.EEG.new_Fs)*(1/paramStruct.initialize.BOLD.TR);

% Save the downsampled preprocessed EEG data
save([fileStruct.paths.MAT_files '/EEG/tempEEG_filtered_downsampled_' num2str(subject) '_' num2str(scan) '.mat'], 'EEG_data', '-v7.3')





                    
                    