function f_conetwork_rewrite_new(preprocessing, subject,trial, chan, arrow_size)
%% f_conetwork_rewrite_new is conetwork_new rewritten and tailored to the format of the Keilholz lab EEG data for the new EEG cap (70 channels) 
%   
%   Syntax:
%   f_conetwork_rewrite_new(preprocessing, subject, trial, chan, arrow_size)
%   
%   PREPROCESSING: Indicate whether data comes from before (enter 0) or after (enter 1) preprocessing
%   SUBJECT: Test subject number
%   TRIAL: Trial number of test subject (e.g. trial "2" of subject 1)
%   CHAN: Channels of interest (a scalar or vector of scalars)
%   ARROW_SIZE: a 1x4 vector of [arrow maximum size, arrow maximum cutoff, arrow minimum size, arrow minimum cutoff]
%
%   Written by Josh Grooms on January 22, 2012


% Initialize workspace parameters
load new_eeg_channels;
load all_clustering_results_new_cap;
load new_EEG;

%% Initialize correlation data & sort labels
if preprocessing == 0
    correlation = all_correlation_maps_before(:, :, subject, trial);
    labels = channels(all_correlation_map_label_locs_before(:, subject, trial));
else
    correlation = all_correlation_maps_after(:, :, subject, trial);
    labels = channels(all_correlation_map_label_locs_after(:, subject, trial));
end

%% Delete irrelevant channels from the data (subjects 7 & later)
% Initialize important variables
s1 = size(correlation);
i = 1;

while i < s1(1)
    
    % Delete PHOTO, AUDIO, O9, O10 data
    if strcmpi(labels{i}, 'PHOTO') | strcmpi(labels{i}, 'AUDIO') | strcmpi(labels{i}, 'O9') | strcmpi(labels{i}, 'O10')
        correlation(i, :) = []; % Delete the row containing this data
        correlation(:, i) = []; % Delete the column containing this data
        s1 = size(correlation); % Update the size of the correlation matrix
        labels(i) = [];         % Delete the label from the cell
    else
        i = i + 1;
    end
end

%% Prepare the adjacency matrix and plot information
% Initialize function-specific parameters
adj = zeros(64);
max_cutoff = arrow_size(2);
min_cutoff = arrow_size(4);
circle = zeros(64, 1);
circle(chan) = 1;
location = [EEG.(labels{1})(1); EEG.(labels{1})(2)];


% Pull electrode coordinates in the same order as the electrodes appear in the data
for j = 2:length(labels)
    location = [location(1, :) EEG.(labels{j})(1); location(2, :) EEG.(labels{j})(2)];
end

% Normalize location matrix for use on a unit square
location = location + 0.45;
location = location/max(max(location));

% Create the adjacency matrix
[row column] = find(correlation > min_cutoff & correlation < max_cutoff);

for i = 1:length(row)
    adj(row(i), column(i)) = correlation(row(i), column(i));
end

%% Create the coherence network
draw_layout_newer(adj,labels, circle, location(1, :), location(2, :), 'ch',arrow_size);