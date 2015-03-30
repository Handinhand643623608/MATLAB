%% s_correlation_vector creates a 1-dimensional vector of the EEG-fMRI correlation data for use in statistical analyses
%   Written by Josh Grooms on 2/16/2012
%         Modified on 3/6/2012

% Initialize variables to be used
subject_numbers = [1 2 4 5 7];
subject_scans = {...
    [1 2]
    [1 2]
    []
    [1 2]
    [1 2]
    []
    [1 2]};
electrodes_to_use = {'FPZ' 'P8'};

% Load the correlation data
if ~exist('all_subject_maps')
    load correlation_results_2012_03_05;
end

% Pre-allocate to avoid memory errors
num_scans = 0;
for i = 1:length(subject_scans)
    num_scans = num_scans + numel(subject_scans{i});
end
catdata = zeros([size(all_subject_maps{1}{1}) num_scans]);

% Concatenate all subjects one matrix along the 6th dimension
k = 1;
for i = subject_numbers
    for j = subject_scans{i}
        catdata(:, :, :, :, :, k) = all_subject_maps{i}{j};
        k = k + 1;
    end
end

% Create the vector of all correlation results
all_corr_vector = catdata(:);

% Eliminate data for channels other than those of interest (channels 1 & 2 of the 5th array dimension)
if size(catdata, 5) > length(electrodes_to_use)
    catdata(:, :, :, :, length(electrodes_to_use):end, :) = [];
end

% Calculate the mean of all subject data
mean_catdata = mean(catdata, 6);

% Create the vector of data
mean_corr_vector = mean_catdata(:);

% Get rid of the zeros
mean_corr_vector(mean_corr_vector == 0) = [];

% Save the data
save(['corr_vectors_' datestr(now, 'yyyymmdd') '.mat'], 'mean_corr_vector', 'all_corr_vector', '-v7.3')
