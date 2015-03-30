function f_conetwork_rewrite(preprocessing, subject,trial, chan, arrow_size)
%% f_conetwork_rewrite is conetwork_new rewritten and tailored to the format of the Keilholz lab EEG data. 
%   
%   Syntax:
%   f_conetwork_rewrite(preprocessing, subject, trial, chan, arrow_size)
%   
%   PREPROCESSING: Indicate whether data comes from before (enter 0) or after (enter 1) preprocessing
%   SUBJECT: Test subject number
%   TRIAL: Trial number of test subject (e.g. trial "2" of subject 1)
%   CHAN: Channels of interest (a scalar or vector of scalars)
%   ARROW_SIZE: a 1x4 vector of [arrow maximum size, arrow maximum cutoff, arrow minimum size, arrow minimum cutoff]
%
%   Written by Josh Grooms on November 16, 2011
%       Heavily modified on January 22, 2012, 2/8/2012


% Initialize workspace parameters
load EEG_labels.mat;
load EEG.mat;

% Select which data to load (depends on subject number)
if subject < 7
    channels = channels(1:64, 1);
    load clustering_results_2012_02_07;
else
    channels = channels(:, 2);
    load clustering_results_2012_02_08;
end

%% Initialize correlation data & sort labels
if preprocessing == 0
    correlation = correlation_maps_before(:, :, subject, trial);
    labels = channels(correlation_map_label_locs_before(:, subject, trial));
else
    correlation = correlation_maps_after(:, :, subject, trial);
    labels = channels(correlation_map_label_locs_after(:, subject, trial));
end


%% Prepare the adjacency matrix and plot information
% Initialize function-specific parameters
s1 = size(correlation);
adj = zeros(s1(1));
max_cutoff = arrow_size(2);
min_cutoff = arrow_size(4);
circle = zeros(s1(1), 1);
circle(chan) = 1;
location = [EEG.(labels{1})(1); EEG.(labels{1})(2)];


% Pull electrode coordinates in the same order as the electrodes appear in the data
for j = 2:length(labels)
    location = [location(1, :) EEG.(labels{j})(1); location(2, :) EEG.(labels{j})(2)];
end

% Create the adjacency matrix
[row column] = find(correlation > min_cutoff & correlation < max_cutoff);

for i = 1:length(row)
    adj(row(i), column(i)) = correlation(row(i), column(i));
end

% Create the coherence network
draw_layout_newer(adj,labels, circle, location(1, :), location(2, :), 'ch',arrow_size);