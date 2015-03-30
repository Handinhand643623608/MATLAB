% Initialize script-specific parameters
subjects = [1 2 4 5 7];
scans = {...
    [1 2]
    [1 2]
    []
    [1 2]
    [1 2]
    []
    [1 2]};
electrodes_of_interest = {'FPZ' 'P8'};
data_switch = 4;

% Load data stored elsewhere
load EEG_labels;

switch data_switch
    case 1
        load eeg_data_20120302_unmodified;
    case 2
        load eeg_data_20120301_global_eeg_remains;
    case 3
        load eeg_data_20120227_global_removed;
    case 4
        load eeg_data_20120301_global_eeg_remains;
end

        

% Determine the number of scans
num_scans = 0;
for i = subjects
    num_scans = num_scans + numel(scans{i});
end

% Pre-allocate data array
% p2p_vals = cell(length(electrodes_of_interest), 1);
% for i = 1:length(electrodes_of_interest)
%     p2p_vals{i} = zeros(num_scans, 4);
% end


%% Determine the peak-to-peak values
for i = 1:length(electrodes_of_interest)
    m = 1;
    for j = subjects
        for k = scans{i}
 
            % Pull the appropriate data from the EEG data set
            if i < 7
                current_data = eeg_data{j}{k}(strcmp(electrodes_of_interest(i), channels(:, 1)), :);
            else
                current_data = eeg_data{j}{k}(strcmp(electrodes_of_interest(i), channels(:, 2)), :);
            end
            
            % Get rid of NaNs in data and convert data to type 'double'
            current_data(isnan(current_data)) = 0;
            current_data = double(current_data);
            
            % Detrend current_data, if applicable
            if data_switch == 4
                current_data = detrend_wm(current_data, 2);
            end
            
            % Collect average peak-to-peak amplitude values
            p2p_vals{i}(m, data_switch) = f_avg_p2p_amplitude(current_data);
            m = m + 1;
        end
    end
end

               