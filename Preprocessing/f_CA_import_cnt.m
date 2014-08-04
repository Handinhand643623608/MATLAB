function EEG_data = f_CA_import_cnt(EEG_data, fileStruct, paramStruct)

%% Initialize
% Initialize function-specific variables
subject = EEG_data.info.subject;
scan = EEG_data.info.scan;
TR = paramStruct.initialize.BOLD.TR;
num_dummy_scans = ceil(3001/(TR*1000));

% Load data stored elsewhere
load EEG_labels

%% Impot the CNT Files    
% Determine the EEG filenames
EEG_filenames = f_CA_filenames(fileStruct.paths.EEG{subject}, 'cnt');
        
% Load the EEG data in EEGLab
current_EEG_data = pop_loadcnt(EEG_filenames{scan}, 'dataformat', 'int32');

% Change EEG labels as necessary
current_channels = cell(length(current_EEG_data.chanlocs), 1);        

for k = length(current_EEG_data.chanlocs):-1:1

    % Overwrite subject 1-4's EEG labels (they were acquired incorrectly)
    if subject < 5
        temp_channel = channels{k, 1};
        if strcmp(paramStruct.preprocess.EEG.BCG_label, temp_channel)
            if ~paramStruct.preprocess.EEG.has_BCG(subject)
                temp_channel = channels{k, 2};
            end
        end
        current_EEG_data.chanlocs(k).labels = temp_channel;                
    end

    % Change the labeling of the BCG channel
    if paramStruct.preprocess.EEG.has_BCG(subject)
        if strcmp(paramStruct.preprocess.EEG.BCG_label, current_EEG_data.chanlocs(k).labels) || strcmp('PHOTO', current_EEG_data.chanlocs(k).labels)
            BCG_index = k;
            current_EEG_data.chanlocs(k).labels = 'BCG';
            current_channels{k} = 'BCG';
        end                
    end

    % Delete 'Audio' and other superfluous channels
    if strcmp('Audio', current_EEG_data.chanlocs(k).labels) || strcmp('PHOTO', current_EEG_data.chanlocs(k).labels) 
        current_EEG_data.data(k, :) = [];
        current_EEG_data.chanlocs(k) = [];
        current_EEG_data.nbchan = length(current_EEG_data.chanlocs);
        current_channels(k) = [];
    elseif ~strcmp('Audio', current_EEG_data.chanlocs(k).labels) && ~strcmp('PHOTO', current_EEG_data.chanlocs(k).labels) && ~strcmp('BCG', current_EEG_data.chanlocs(k).labels)
        current_channels{k} = current_EEG_data.chanlocs(k).labels;
    end
end

% Data conditioning
current_EEG_data.data(isnan(current_EEG_data.data)) = 0;
current_EEG_data.data = double(current_EEG_data.data);

% Artifact detection
if strcmpi(paramStruct.preprocess.EEG.MR_correct_channel, 'auto')
    MR_correct_channel = DetectChannel(current_EEG_data);
else
    MR_correct_channel = paramStruct.preprocess.EEG.MR_correct_channel;
end

% Create a list of channels for MR artifact detection
temp = 1:size(current_EEG_data.data, 1);
MR_channels = [MR_correct_channel temp(temp ~= MR_correct_channel)];

% Initialize parameters for MR artifact detection
peak_references = 0;
channel_index = 0;
prct_index = 1;

% Loop until a percentage threshold is found
while length(peak_references) ~= (num_dummy_scans + paramStruct.preprocess.EEG.num_timepoints)
    % Increment the channel to try
    channel_index = channel_index + 1;

    % If the loop is too long, warn & return
    if channel_index > length(MR_channels)
        prct_index = prct_index + 1;
        channel_index = 1;
        if prct_index > length(paramStruct.preprocess.EEG.prct_thresholds)
            warning('No appropriate channel found to perform MR artifact correction. No EEG data loaded');
            return;
        end
    end

    % Get the channel & threshold to use
    channel_to_try = MR_channels(channel_index);
    prct_thresh = paramStruct.preprocess.EEG.prct_thresholds(prct_index);

    % Find the fMRI artifacts
    try
        [peak_references, NU1, real_TR, NU2] = DetectMarkers(current_EEG_data, TR*1000, 0, prct_thresh, channel_to_try);
    catch DM_error
        if ~strcmp(DM_error.identifier, 'MATLAB:badsubscript')
            throw(DM_error);
        end
    end
end

% Garbage collect
clear NU*

% Bergen artifact detection & correction
artifact_onset = 0;
artifact_offset = current_EEG_data.srate*TR + 1;
weighting_mat = m_moving_average(paramStruct.preprocess.EEG.num_timepoints + num_dummy_scans, paramStruct.initialize.BOLD.num_slices);
current_EEG_data = CorrectionMatrix(current_EEG_data, weighting_mat, peak_references, artifact_onset, artifact_offset);

% Filter BCG data before correction
if paramStruct.preprocess.EEG.has_BCG(subject)
    tempBCGdata = current_EEG_data.data(BCG_index, :);
    tempBCGdata = tempBCGdata';
    tempBCGdata = resample(tempBCGdata, (length(tempBCGdata)*(paramStruct.preprocess.EEG.new_Fs/current_EEG_data.srate)), length(tempBCGdata));
    [tempBCGdata tempBCGshift] = firfilt(tempBCGdata, 0.5, 25, current_EEG_data.srate, paramStruct.preprocess.EEG.filt_params);
    tempBCGdata = tempBCGdata(tempBCGshift:end);
    tempBCGdata = resample(tempBCGdata, size(current_EEG_data.data, 2), length(tempBCGdata));
    current_EEG_data.data(BCG_index, :) = tempBCGdata;
end

% FMRIB BCG correction
if paramStruct.preprocess.EEG.has_BCG(subject)
    current_EEG_data = pop_fmrib_qrsdetect(current_EEG_data, BCG_index, 'qrs', 'no');
    current_EEG_data = eeg_checkset(current_EEG_data);
    current_EEG_data = pop_fmrib_pas(current_EEG_data, 'qrs', 'mean');
end

% Get sample positions that correspond to MRI
MR_start_position = peak_references(num_dummy_scans + 1);
MR_stop_position = peak_references(num_dummy_scans + paramStruct.preprocess.EEG.num_timepoints) + current_EEG_data.srate*TR + 1;        

if ~isempty(paramStruct.preprocess.EEG.new_Fs)
    MR_start_position = round(MR_start_position*paramStruct.preprocess.EEG.new_Fs/current_EEG_data.srate);
    MR_stop_position = round(MR_stop_position*paramStruct.preprocess.EEG.new_Fs/current_EEG_data.srate);
    current_EEG_data = pop_resample(current_EEG_data, paramStruct.preprocess.EEG.new_Fs);
end

% Crop to MRI incident
current_EEG_data = current_EEG_data.data;
current_EEG_data = current_EEG_data(:, MR_start_position:MR_stop_position);

% Extract BCG channel data & store in output structure
if paramStruct.preprocess.EEG.has_BCG(subject)
    BCG_data = current_EEG_data(BCG_index, :);
    current_EEG_data(BCG_index, :) = [];
    EEG_data.data.BCG = double(BCG_data);
end

% Delete useless unknown channels (if they exist)

% Store the data
EEG_data.data.EEG = double(current_EEG_data);
EEG_data.info.channels = current_channels;
EEG_data.info.Fs = paramStruct.preprocess.EEG.new_Fs;

% Save the raw EEG data
if ~exist([fileStruct.paths.MAT_files '/EEG'], 'dir')
    mkdir([fileStruct.paths.MAT_files '/EEG'])
end
save([fileStruct.paths.MAT_files '/EEG/tempEEG_raw_' num2str(subject) '_' num2str(scan) '.mat'], 'EEG_data', '-v7.3')
            
        
        
        
        
    

